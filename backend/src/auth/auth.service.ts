import {
  Injectable,
  Logger,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { createHash, randomBytes, randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { getAppEnv } from '../config/app-env';
import { CustomerService } from '../customer/customer.service';
import { FirebaseAdminService } from '../notification/firebase-admin.service';
import {
  ACCESS_SCOPES,
  AuthTokens,
  ShieldJwtPayload,
  ShieldPrincipal,
  ShieldPrincipalType,
  USER_TYPES,
} from './auth.types';

type StoredRefreshSession = {
  sessionId: string;
  principal: ShieldPrincipal;
};

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly env = getAppEnv();

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly redisService: RedisService,
    private readonly firebaseAdminService: FirebaseAdminService,
    private readonly customerService: CustomerService,
  ) {}

  async loginCustomer(firebaseIdToken: string) {
    const decoded = await this.verifyFirebaseToken(firebaseIdToken);
    const provider = this.getFirebaseProvider(decoded);
    if (provider !== 'phone') {
      throw new UnauthorizedException(
        'Customer login must use Firebase phone OTP.',
      );
    }

    const mobile = decoded.phone_number?.trim();
    if (!mobile) {
      throw new UnauthorizedException(
        'Firebase phone sign-in did not include a mobile number.',
      );
    }

    const customer = await this.prisma.customer.findFirst({
      where: {
        deletedAt: null,
        OR: [
          { firebaseUid: decoded.uid },
          { mobile },
        ],
      },
      select: {
        id: true,
        uuid: true,
        mobile: true,
        email: true,
        status: true,
        firebaseUid: true,
      },
    });

    if (!customer) {
      throw new UnauthorizedException(
        'Customer is not provisioned in SHIELD.',
      );
    }

    if (
      customer.status &&
      ['SUSPENDED', 'INACTIVE', 'DELETED'].includes(customer.status.toUpperCase())
    ) {
      throw new UnauthorizedException(
        `Customer status ${customer.status} is not allowed to sign in.`,
      );
    }

    await this.prisma.customer.update({
      where: { id: customer.id },
      data: {
        firebaseUid: decoded.uid,
        lastLoginAt: new Date(),
      },
    });

    const principal = await this.buildPrincipal({
      subjectId: customer.uuid,
      principalType: 'CUSTOMER',
      firebaseUid: decoded.uid,
      authProvider: provider,
      customerId: customer.id.toString(),
      mobile: customer.mobile,
      email: customer.email ?? undefined,
      roleCode: 'CUSTOMER',
      userType: 'CUSTOMER',
      accessScope: 'SELF',
    });

    return this.issueTokens(principal);
  }

  async registerCustomer(firebaseIdToken: string, body: any) {
    const decoded = await this.verifyFirebaseToken(firebaseIdToken);
    const provider = this.getFirebaseProvider(decoded);
    if (provider !== 'phone') {
      throw new UnauthorizedException(
        'Customer registration must use Firebase phone OTP.',
      );
    }

    const mobile = decoded.phone_number?.trim();
    if (!mobile) {
      throw new UnauthorizedException(
        'Firebase phone sign-in did not include a mobile number.',
      );
    }

    const existingCustomer = await this.prisma.customer.findFirst({
      where: {
        deletedAt: null,
        OR: [{ firebaseUid: decoded.uid }, { mobile }],
      },
      select: { id: true },
    });

    if (existingCustomer) {
      return this.loginCustomer(firebaseIdToken);
    }

    const normalizedName = (body.name ?? '').toString().trim();
    const [firstName, ...lastNameParts] = normalizedName
      .split(RegExp('\\s+'))
      .filter(Boolean);

    if (!firstName) {
      throw new UnauthorizedException('Customer name is required.');
    }

    await this.customerService.create({
      first_name: firstName,
      last_name: lastNameParts.join(' '),
      dob: body.dob,
      gender: body.gender,
      mobile,
      email: body.email,
      agent_code: body.agent_code,
      referred_by_code: body.referred_by_code,
    });

    return this.loginCustomer(firebaseIdToken);
  }

  async loginInternalUser(firebaseIdToken: string) {
    const decoded = await this.verifyFirebaseToken(firebaseIdToken);
    const provider = this.getFirebaseProvider(decoded);
    if (provider !== 'google.com') {
      throw new UnauthorizedException(
        'Internal users must use Firebase Google sign-in.',
      );
    }

    const email = decoded.email?.trim().toLowerCase();
    if (!email) {
      throw new UnauthorizedException(
        'Google sign-in did not provide an email address.',
      );
    }

    const user = await this.prisma.user.findFirst({
      where: {
        deletedAt: null,
        OR: [{ firebaseUid: decoded.uid }, { email }],
      },
      include: {
        role: {
          include: {
            rolePermissions: {
              include: {
                permission: true,
              },
            },
          },
        },
      },
    });

    if (!user) {
      throw new UnauthorizedException('Internal user is not provisioned.');
    }

    if (
      user.status &&
      ['SUSPENDED', 'INACTIVE', 'DELETED'].includes(user.status.toUpperCase())
    ) {
      throw new UnauthorizedException(
        `User status ${user.status} is not allowed to sign in.`,
      );
    }

    if (!user.role?.code) {
      throw new UnauthorizedException(
        'Provisioned user does not have an assigned SHIELD role.',
      );
    }

    await this.prisma.user.update({
      data: {
        firebaseUid: decoded.uid,
        authProvider: provider,
        userType: this.toUserType(user.userType ?? user.role.userType),
        accessScope: this.toAccessScope(
          user.accessScope ?? user.role.defaultScope,
          'BRANCH',
        ),
        lastLoginAt: new Date(),
      },
      where: { id: user.id },
    });

    const principal = await this.buildPrincipal({
      subjectId: user.uuid,
      principalType: user.role.isSystemRole ? 'SYSTEM' : 'USER',
      firebaseUid: decoded.uid,
      authProvider: provider,
      userId: user.id.toString(),
      email,
      mobile: user.mobile ?? undefined,
      branchBusinessId: user.branchBusinessId?.toString(),
      roleCode: user.role.code,
      userType: this.toUserType(user.userType ?? user.role.userType),
      accessScope: this.toAccessScope(
        user.accessScope ?? user.role.defaultScope,
        'BRANCH',
      ),
      permissions: user.role.rolePermissions
        .map((entry) => entry.permission.code)
        .filter((value): value is string => !!value),
    });

    return this.issueTokens(principal);
  }

  async refresh(refreshToken: string) {
    const normalized = refreshToken.trim();
    if (!normalized) {
      throw new UnauthorizedException('Refresh token is required.');
    }

    const key = this.getRefreshKey(normalized);
    const stored = await this.getStoredRefreshSession(key);
    if (!stored) {
      throw new UnauthorizedException('Refresh token is invalid or expired.');
    }

    const session = JSON.parse(stored) as StoredRefreshSession;
    await this.redisService.delete(key);
    return this.issueTokens(session.principal, session.sessionId);
  }

  async logout(refreshToken: string | undefined, principal?: ShieldPrincipal) {
    if (refreshToken?.trim()) {
      const key = this.getRefreshKey(refreshToken.trim());
      const stored = await this.getStoredRefreshSession(key);
      if (stored) {
        const session = JSON.parse(stored) as StoredRefreshSession;
        await this.revokeSession(
          session.sessionId,
          this.parseDurationToSeconds(this.env.jwtRefreshTtl),
        );
        await this.redisService.delete(key);
      }
    }

    if (principal) {
      await this.revokeSession(
        principal.sessionId,
        this.parseDurationToSeconds(this.env.jwtRefreshTtl),
      );
    }

    return { success: true };
  }

  async verifyAccessToken(token: string) {
    try {
      const payload = await this.jwtService.verifyAsync<ShieldJwtPayload>(token, {
        secret: this.env.jwtAccessSecret,
      });

      const revoked = await this.redisService.get(this.getRevokedKey(payload.sid));
      if (revoked) {
        throw new UnauthorizedException('Session has been revoked.');
      }

      return this.mapPayloadToPrincipal(payload);
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Invalid or expired SHIELD access token.');
    }
  }

  async getProfile(principal: ShieldPrincipal) {
    if (principal.principalType === 'CUSTOMER' && principal.customerId) {
      const customer = await this.prisma.customer.findUnique({
        where: { id: BigInt(principal.customerId) },
      });
      return {
        principal,
        profile: customer,
      };
    }

    if (principal.userId) {
      const user = await this.prisma.user.findUnique({
        where: { id: BigInt(principal.userId) },
        include: {
          role: true,
          department: true,
          branchBusiness: true,
        },
      });
      return {
        principal,
        profile: user,
      };
    }

    return {
      principal,
      profile: null,
    };
  }

  private async buildPrincipal(input: {
    subjectId: string;
    principalType: ShieldPrincipalType;
    firebaseUid: string;
    authProvider: string;
    customerId?: string;
    userId?: string;
    email?: string;
    mobile?: string;
    branchBusinessId?: string;
    roleCode: string;
    userType: ShieldPrincipal['userType'];
    accessScope: ShieldPrincipal['accessScope'];
    permissions?: string[];
  }): Promise<ShieldPrincipal> {
    const permissions =
      input.permissions ?? (await this.getPermissionsForRole(input.roleCode));

    return {
      subjectId: input.subjectId,
      sessionId: randomUUID(),
      principalType: input.principalType,
      roleCode: input.roleCode,
      userType: input.userType,
      accessScope: input.accessScope,
      permissions,
      firebaseUid: input.firebaseUid,
      authProvider: input.authProvider,
      customerId: input.customerId,
      userId: input.userId,
      email: input.email,
      mobile: input.mobile,
      branchBusinessId: input.branchBusinessId,
    };
  }

  private async issueTokens(
    principal: ShieldPrincipal,
    existingSessionId?: string,
  ): Promise<AuthTokens> {
    const sessionId = existingSessionId ?? principal.sessionId;
    const effectivePrincipal = { ...principal, sessionId };
    const payload: ShieldJwtPayload = {
      sub: effectivePrincipal.subjectId,
      sid: sessionId,
      pty: effectivePrincipal.principalType,
      role: effectivePrincipal.roleCode,
      userType: effectivePrincipal.userType,
      scope: effectivePrincipal.accessScope,
      permissions: effectivePrincipal.permissions,
      firebaseUid: effectivePrincipal.firebaseUid,
      authProvider: effectivePrincipal.authProvider,
      customerId: effectivePrincipal.customerId,
      userId: effectivePrincipal.userId,
      email: effectivePrincipal.email,
      mobile: effectivePrincipal.mobile,
      branchBusinessId: effectivePrincipal.branchBusinessId,
    };

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.env.jwtAccessSecret,
      expiresIn: this.env.jwtAccessTtl as any,
    });

    const refreshToken = randomBytes(48).toString('hex');
    try {
      await this.redisService.set(
        this.getRefreshKey(refreshToken),
        JSON.stringify({
          sessionId,
          principal: effectivePrincipal,
        } satisfies StoredRefreshSession),
        this.parseDurationToSeconds(this.env.jwtRefreshTtl),
      );
    } catch (error) {
      this.logger.error(
        `Failed to persist auth session in Redis: ${error}`,
      );
      throw new ServiceUnavailableException(
        'Authentication session store is unavailable. Please try again shortly.',
      );
    }

    return {
      accessToken,
      refreshToken,
      accessTokenExpiresIn: this.env.jwtAccessTtl,
      refreshTokenExpiresIn: this.env.jwtRefreshTtl,
      principal: effectivePrincipal,
    };
  }

  private async getPermissionsForRole(roleCode: string) {
    const role = await this.prisma.role.findFirst({
      where: { code: roleCode },
      include: {
        rolePermissions: {
          include: {
            permission: true,
          },
        },
      },
    });

    return role?.rolePermissions
      .map((entry) => entry.permission.code)
      .filter((value): value is string => !!value) ?? [];
  }

  private getFirebaseProvider(decoded: Record<string, any>) {
    return (
      decoded.firebase?.sign_in_provider?.toString().trim() ||
      decoded.sign_in_provider?.toString().trim() ||
      ''
    );
  }

  private async verifyFirebaseToken(firebaseIdToken: string) {
    try {
      return await this.firebaseAdminService.verifyIdToken(firebaseIdToken);
    } catch (_error) {
      throw new UnauthorizedException('Invalid Firebase ID token.');
    }
  }

  private mapPayloadToPrincipal(payload: ShieldJwtPayload): ShieldPrincipal {
    return {
      subjectId: payload.sub,
      sessionId: payload.sid,
      principalType: payload.pty,
      roleCode: payload.role,
      userType: payload.userType,
      accessScope: payload.scope,
      permissions: payload.permissions ?? [],
      firebaseUid: payload.firebaseUid,
      authProvider: payload.authProvider,
      customerId: payload.customerId,
      userId: payload.userId,
      email: payload.email,
      mobile: payload.mobile,
      branchBusinessId: payload.branchBusinessId,
    };
  }

  private parseDurationToSeconds(value: string) {
    const trimmed = value.trim().toLowerCase();
    const match = trimmed.match(/^(\d+)([smhd])$/);
    if (!match) {
      const parsed = Number(trimmed);
      return Number.isFinite(parsed) ? parsed : 0;
    }

    const amount = Number(match[1]);
    const unit = match[2];
    const multiplier =
      unit === 's'
        ? 1
        : unit === 'm'
          ? 60
          : unit === 'h'
            ? 3600
            : 86400;
    return amount * multiplier;
  }

  private getRefreshKey(refreshToken: string) {
    return `auth:refresh:${this.hashToken(refreshToken)}`;
  }

  private async getStoredRefreshSession(key: string) {
    try {
      return await this.redisService.get(key);
    } catch (error) {
      this.logger.error(`Failed to read auth session from Redis: ${error}`);
      throw new ServiceUnavailableException(
        'Authentication session store is unavailable. Please try again shortly.',
      );
    }
  }

  private getRevokedKey(sessionId: string) {
    return `auth:revoked:${sessionId}`;
  }

  private async revokeSession(sessionId: string, ttlSeconds: number) {
    try {
      await this.redisService.set(
        this.getRevokedKey(sessionId),
        '1',
        ttlSeconds > 0 ? ttlSeconds : 300,
      );
    } catch (error) {
      this.logger.warn(`Failed to revoke session ${sessionId}: ${error}`);
    }
  }

  private hashToken(value: string) {
    return createHash('sha256').update(value).digest('hex');
  }

  private toUserType(value: string | null | undefined): ShieldPrincipal['userType'] {
    return USER_TYPES.includes(value as ShieldPrincipal['userType'])
      ? (value as ShieldPrincipal['userType'])
      : 'EMPLOYEE';
  }

  private toAccessScope(
    value: string | null | undefined,
    fallback: ShieldPrincipal['accessScope'],
  ): ShieldPrincipal['accessScope'] {
    return ACCESS_SCOPES.includes(value as ShieldPrincipal['accessScope'])
      ? (value as ShieldPrincipal['accessScope'])
      : fallback;
  }
}
