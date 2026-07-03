import {
  Injectable,
  Logger,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Prisma } from '@prisma/client';
import { createHash, randomBytes, randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { getAppEnv } from '../config/app-env';
import { CustomerService } from '../customer/customer.service';
import {
  ACCESS_SCOPES,
  type AuthRequestContext,
  type AuthTokens,
  type ShieldJwtPayload,
  type ShieldPrincipal,
  type ShieldPrincipalType,
  USER_TYPES,
} from './auth.types';
import { FirebaseAdminService } from '../notification/firebase-admin.service';
import { getRolePermissions } from './rbac-catalog';

type SessionRecord = {
  id: bigint;
  sessionId: string;
  subjectId: string;
  principalType: string;
  roleCode: string | null;
  userType: string | null;
  accessScope: string | null;
  permissions: unknown;
  firebaseUid: string | null;
  authProvider: string | null;
  customerId: bigint | null;
  userId: bigint | null;
  email: string | null;
  mobile: string | null;
  branchBusinessId: string | null;
};

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly env = getAppEnv();

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly firebaseAdminService: FirebaseAdminService,
    private readonly customerService: CustomerService,
  ) {}

  async loginCustomer(
    firebaseIdToken: string,
    requestContext?: AuthRequestContext,
  ) {
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
        OR: [{ firebaseUid: decoded.uid }, { mobile }],
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
      throw new UnauthorizedException('Customer is not provisioned in SHIELD.');
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

    const tokens = await this.issueTokens(principal, {
      ...requestContext,
      loginMethod: requestContext?.loginMethod ?? 'PHONE_OTP',
    });
    await this.runAuthStoreOperation('record_login_history', () =>
      this.recordLoginHistory(principal, {
        ...requestContext,
        loginMethod: requestContext?.loginMethod ?? 'PHONE_OTP',
      }),
    );
    return tokens;
  }

  async registerCustomer(
    firebaseIdToken: string,
    body: any,
    requestContext?: AuthRequestContext,
  ) {
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
      return this.loginCustomer(firebaseIdToken, requestContext);
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

    return this.loginCustomer(firebaseIdToken, requestContext);
  }

  async loginInternalUser(
    firebaseIdToken: string,
    requestContext?: AuthRequestContext,
  ) {
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
      permissions: this.mergeRolePermissions(
        user.role.code,
        user.role.rolePermissions
          .map((entry) => entry.permission.code)
          .filter((value): value is string => !!value),
      ),
    });

    const tokens = await this.issueTokens(principal, {
      ...requestContext,
      loginMethod: requestContext?.loginMethod ?? 'GOOGLE_SIGN_IN',
    });
    await this.runAuthStoreOperation('record_login_history', () =>
      this.recordLoginHistory(principal, {
        ...requestContext,
        loginMethod: requestContext?.loginMethod ?? 'GOOGLE_SIGN_IN',
      }),
    );
    return tokens;
  }

  async refresh(refreshToken: string, requestContext?: AuthRequestContext) {
    const normalized = refreshToken.trim();
    if (!normalized) {
      throw new UnauthorizedException('Refresh token is required.');
    }

    const hash = this.hashToken(normalized);
    const session = await this.runAuthStoreOperation('refresh_lookup', () =>
      this.prisma.authSession.findFirst({
        where: {
          refreshTokenHash: hash,
          revokedAt: null,
          refreshTokenExpiresAt: { gt: new Date() },
        },
        select: {
          id: true,
          sessionId: true,
          subjectId: true,
          principalType: true,
          roleCode: true,
          userType: true,
          accessScope: true,
          permissions: true,
          firebaseUid: true,
          authProvider: true,
          customerId: true,
          userId: true,
          email: true,
          mobile: true,
          branchBusinessId: true,
        },
      }),
    );

    if (!session) {
      throw new UnauthorizedException('Refresh token is invalid or expired.');
    }

    const principal = await this.rehydrateSessionPrincipal(session);
    return this.issueTokens(principal, requestContext, session.sessionId);
  }

  async logout(refreshToken: string | undefined, principal?: ShieldPrincipal) {
    if (refreshToken?.trim()) {
      const refreshTokenHash = this.hashToken(refreshToken.trim());
      await this.prisma.authSession.updateMany({
        where: {
          refreshTokenHash,
          revokedAt: null,
        },
        data: {
          revokedAt: new Date(),
          revokedReason: 'USER_LOGOUT',
          isCurrent: false,
        },
      });
    }

    if (principal) {
      await this.revokeSessionById(principal.sessionId, 'USER_LOGOUT');
    }

    return { success: true };
  }

  async verifyAccessToken(token: string) {
    try {
      const payload = await this.jwtService.verifyAsync<ShieldJwtPayload>(token, {
        secret: this.env.jwtAccessSecret,
      });

      const session = await this.runAuthStoreOperation(
        'access_token_session_lookup',
        () =>
          this.prisma.authSession.findUnique({
            where: { sessionId: payload.sid },
            select: { revokedAt: true },
          }),
      );

      if (!session || session.revokedAt) {
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
          providerProfile: {
            select: {
              id: true,
              displayName: true,
              specialization: true,
              themePreference: true,
              languagePreference: true,
              defaultPrinter: true,
              timezone: true,
            },
          },
        },
      });
      return {
        principal: {
          ...principal,
          roleLabel: this.getRoleLabel(user?.role?.name, principal.roleCode),
          branchLabel: this.getBranchLabel({
            businessName: user?.branchBusiness?.name,
            businessCode: user?.branchBusiness?.code,
            roleCode: principal.roleCode,
            departmentCode: user?.department?.code,
          }),
          displayName:
            user?.providerProfile?.displayName?.trim() ||
            this.getDisplayName(user?.firstName, user?.lastName, principal.email),
        },
        profile: user,
        display: user
          ? {
              fullName:
                user.providerProfile?.displayName?.trim() ||
                this.getDisplayName(
                  user.firstName,
                  user.lastName,
                  user.email ?? undefined,
                ),
              designation: this.getRoleLabel(user.role?.name, principal.roleCode),
              departmentName: user.department?.name ?? null,
              branch: user.branchBusiness
                ? {
                    id: user.branchBusiness.id.toString(),
                    code: user.branchBusiness.code,
                    name: this.getBranchLabel({
                      businessName: user.branchBusiness.name,
                      businessCode: user.branchBusiness.code,
                      roleCode: principal.roleCode,
                      departmentCode: user.department?.code,
                    }),
                    status: user.branchBusiness.status,
                    businessType: user.branchBusiness.businessType,
                  }
                : null,
              email: user.email,
              mobile: user.mobile,
              employeeCode: user.employeeCode,
              roleCode: principal.roleCode,
              providerProfile: user.providerProfile,
            }
          : null,
      };
    }

    return {
      principal,
      profile: null,
    };
  }

  private getDisplayName(
    firstName?: string | null,
    lastName?: string | null,
    fallback?: string,
  ) {
    const fullName = `${firstName ?? ''} ${lastName ?? ''}`.trim();
    return fullName || fallback || 'SHIELD User';
  }

  private getRoleLabel(roleName?: string | null, roleCode?: string | null) {
    if (roleName && roleName.trim().length > 0) {
      return roleName.trim();
    }
    switch (roleCode) {
      case 'ADMIN':
        return 'Administrator';
      case 'SHIELD_AGENT':
        return 'SHIELD Agent';
      case 'CRM_EXECUTIVE':
        return 'CRM Executive';
      case 'PHARMACY_PROVIDER':
        return 'Pharmacist';
      case 'LAB_PROVIDER':
        return 'Laboratory';
      case 'DOCTOR':
        return 'Doctor';
      case 'HOMECARE_PROVIDER':
        return 'Home Care';
      case 'DENTAL_PROVIDER':
        return 'Dentist';
      case 'COSMETIC_PROVIDER':
        return 'Cosmetic Clinic';
      case 'DIETITIAN':
        return 'Dietitian';
      default:
        return roleCode?.replaceAll('_', ' ') ?? 'Provider';
    }
  }

  private getBranchLabel(input: {
    businessName?: string | null;
    businessCode?: string | null;
    roleCode?: string | null;
    departmentCode?: string | null;
  }) {
    if (input.businessCode === 'HYP-PERINTHALMANNA') {
      return 'Sahakar Hyper Pharmacy - Perinthalmanna';
    }
    if (input.businessCode === 'HYP-MANJERI') {
      return 'Sahakar Hyper Pharmacy - Manjeri';
    }
    if (input.businessCode === 'SHG') {
      if (input.roleCode === 'ADMIN') {
        return 'SHG Head Office';
      }
      if (input.roleCode === 'DENTAL_PROVIDER' || input.departmentCode === 'DENTAL') {
        return 'SHG Dental Care';
      }
      if (input.roleCode === 'DOCTOR' || input.departmentCode === 'CLINIC') {
        return 'SHG Medical Centre';
      }
    }
    return input.businessName?.trim() || 'Branch not assigned';
  }

  async listSessions(principal: ShieldPrincipal) {
    const owner = this.getOwnerFromPrincipal(principal);
    const sessions = await this.prisma.authSession.findMany({
      where: {
        ownerType: owner.ownerType,
        ownerId: owner.ownerId,
      },
      include: {
        authDevice: true,
      },
      orderBy: [{ revokedAt: 'asc' }, { lastSeenAt: 'desc' }],
    });

    return sessions.map((session) => ({
      sessionId: session.sessionId,
      roleCode: session.roleCode,
      loginMethod: session.loginMethod,
      createdAt: session.createdAt,
      lastSeenAt: session.lastSeenAt,
      refreshTokenExpiresAt: session.refreshTokenExpiresAt,
      revokedAt: session.revokedAt,
      isCurrent: session.sessionId === principal.sessionId,
      device: session.authDevice
        ? {
            id: session.authDevice.id.toString(),
            uuid: session.authDevice.uuid,
            deviceName: session.authDevice.deviceName,
            platform: session.authDevice.platform,
            browser: session.authDevice.browser,
            os: session.authDevice.os,
            isTrusted: session.authDevice.isTrusted,
            firstSeenAt: session.authDevice.firstSeenAt,
            lastSeenAt: session.authDevice.lastSeenAt,
          }
        : null,
    }));
  }

  async listLoginHistory(principal: ShieldPrincipal, limit = 20) {
    const owner = this.getOwnerFromPrincipal(principal);
    const rows = await this.prisma.loginHistory.findMany({
      where: {
        ownerType: owner.ownerType,
        ownerId: owner.ownerId,
      },
      include: {
        authDevice: true,
      },
      orderBy: { createdAt: 'desc' },
      take: Math.min(Math.max(limit, 1), 50),
    });

    return rows.map((row) => ({
      id: row.id.toString(),
      status: row.status,
      reason: row.reason,
      loginMethod: row.loginMethod,
      sessionId: row.sessionId,
      ipAddress: row.ipAddress,
      createdAt: row.createdAt,
      device: row.authDevice
        ? {
            deviceName: row.authDevice.deviceName,
            platform: row.authDevice.platform,
            browser: row.authDevice.browser,
            os: row.authDevice.os,
          }
        : null,
    }));
  }

  async revokeOwnedSession(
    principal: ShieldPrincipal,
    targetSessionId: string,
  ) {
    const owner = this.getOwnerFromPrincipal(principal);
    const session = await this.prisma.authSession.findFirst({
      where: {
        sessionId: targetSessionId,
        ownerType: owner.ownerType,
        ownerId: owner.ownerId,
      },
      select: { sessionId: true },
    });

    if (!session) {
      throw new UnauthorizedException('Session not found for principal.');
    }

    await this.revokeSessionById(targetSessionId, 'OWNER_REVOKED');
    return { success: true };
  }

  async revokeOtherOwnedSessions(principal: ShieldPrincipal) {
    const owner = this.getOwnerFromPrincipal(principal);
    const sessions = await this.prisma.authSession.findMany({
      where: {
        ownerType: owner.ownerType,
        ownerId: owner.ownerId,
        sessionId: { not: principal.sessionId },
        revokedAt: null,
      },
      select: { sessionId: true },
    });

    for (const session of sessions) {
      await this.revokeSessionById(session.sessionId, 'OWNER_REVOKED_OTHER');
    }

    return {
      success: true,
      revokedSessionCount: sessions.length,
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
    requestContext?: AuthRequestContext,
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
    await this.runAuthStoreOperation('persist_session', () =>
      this.persistSession(
        effectivePrincipal,
        refreshToken,
        requestContext,
        existingSessionId,
      ),
    );

    return {
      accessToken,
      refreshToken,
      accessTokenExpiresIn: this.env.jwtAccessTtl,
      refreshTokenExpiresIn: this.env.jwtRefreshTtl,
      principal: effectivePrincipal,
    };
  }

  private async persistSession(
    principal: ShieldPrincipal,
    refreshToken: string,
    requestContext?: AuthRequestContext,
    existingSessionId?: string,
  ) {
    const owner = this.getOwnerFromPrincipal(principal);
    const device = await this.ensureAuthDevice(principal, requestContext);
    const refreshTokenExpiresAt = new Date(
      Date.now() + this.parseDurationToSeconds(this.env.jwtRefreshTtl) * 1000,
    );
    const refreshTokenHash = this.hashToken(refreshToken);
    const now = new Date();

    if (device) {
      await this.prisma.authSession.updateMany({
        where: {
          ownerType: owner.ownerType,
          ownerId: owner.ownerId,
          authDeviceId: device.id,
          sessionId: { not: principal.sessionId },
          revokedAt: null,
        },
        data: {
          isCurrent: false,
        },
      });
    }

    const data = {
      ownerType: owner.ownerType,
      ownerId: owner.ownerId,
      subjectId: principal.subjectId,
      customerId: owner.customerId,
      userId: owner.userId,
      authDeviceId: device?.id,
      principalType: principal.principalType,
      roleCode: principal.roleCode,
      userType: principal.userType,
      accessScope: principal.accessScope,
      permissions: principal.permissions as any,
      firebaseUid: principal.firebaseUid,
      authProvider: principal.authProvider,
      email: principal.email,
      mobile: principal.mobile,
      branchBusinessId: principal.branchBusinessId,
      loginMethod: requestContext?.loginMethod ?? principal.authProvider,
      refreshTokenHash,
      refreshTokenExpiresAt,
      lastSeenAt: now,
      ipAddress: requestContext?.ipAddress,
      userAgent: requestContext?.userAgent,
      revokedAt: null,
      revokedReason: null,
      isCurrent: true,
    };

    if (existingSessionId) {
      await this.prisma.authSession.update({
        where: { sessionId: existingSessionId },
        data,
      });
      return;
    }

    await this.prisma.authSession.create({
      data: {
        uuid: randomUUID(),
        sessionId: principal.sessionId,
        ...data,
      },
    });
  }

  private async ensureAuthDevice(
    principal: ShieldPrincipal,
    requestContext?: AuthRequestContext,
  ) {
    const owner = this.getOwnerFromPrincipal(principal);
    const fingerprintHash = this.buildDeviceFingerprint(requestContext);
    const now = new Date();

    const existing = await this.prisma.authDevice.findFirst({
      where: {
        ownerType: owner.ownerType,
        ownerId: owner.ownerId,
        fingerprintHash,
      },
    });

    if (existing) {
      return this.prisma.authDevice.update({
        where: { id: existing.id },
        data: {
          deviceId: requestContext?.deviceId ?? existing.deviceId,
          deviceName: requestContext?.deviceName ?? existing.deviceName,
          platform: requestContext?.platform ?? existing.platform,
          browser: requestContext?.browser ?? existing.browser,
          os: requestContext?.os ?? existing.os,
          ipAddress: requestContext?.ipAddress ?? existing.ipAddress,
          userAgent: requestContext?.userAgent ?? existing.userAgent,
          lastSeenAt: now,
        },
      });
    }

    return this.prisma.authDevice.create({
      data: {
        uuid: randomUUID(),
        ownerType: owner.ownerType,
        ownerId: owner.ownerId,
        customerId: owner.customerId,
        userId: owner.userId,
        fingerprintHash,
        deviceId: requestContext?.deviceId,
        deviceName: requestContext?.deviceName,
        platform: requestContext?.platform,
        browser: requestContext?.browser,
        os: requestContext?.os,
        ipAddress: requestContext?.ipAddress,
        userAgent: requestContext?.userAgent,
        firstSeenAt: now,
        lastSeenAt: now,
      },
    });
  }

  private async recordLoginHistory(
    principal: ShieldPrincipal,
    requestContext?: AuthRequestContext,
  ) {
    const owner = this.getOwnerFromPrincipal(principal);
    const fingerprintHash = this.buildDeviceFingerprint(requestContext);
    const device = await this.prisma.authDevice.findFirst({
      where: {
        ownerType: owner.ownerType,
        ownerId: owner.ownerId,
        fingerprintHash,
      },
      select: { id: true },
    });

    await this.prisma.loginHistory.create({
      data: {
        uuid: randomUUID(),
        ownerType: owner.ownerType,
        ownerId: owner.ownerId,
        customerId: owner.customerId,
        userId: owner.userId,
        authDeviceId: device?.id,
        sessionId: principal.sessionId,
        loginMethod: requestContext?.loginMethod ?? principal.authProvider,
        status: 'SUCCESS',
        reason: null,
        ipAddress: requestContext?.ipAddress,
        userAgent: requestContext?.userAgent,
      },
    });
  }

  private async runAuthStoreOperation<T>(
    action: string,
    operation: () => Promise<T>,
  ): Promise<T> {
    try {
      return await operation();
    } catch (error) {
      if (this.isAuthStoreSchemaError(error)) {
        this.logger.error(
          `Auth store schema is unavailable during ${action}.`,
          error instanceof Error ? error.stack : undefined,
        );
        throw new ServiceUnavailableException(
          'Authentication session store is temporarily unavailable. Please try again shortly.',
        );
      }

      throw error;
    }
  }

  private isAuthStoreSchemaError(error: unknown) {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      return ['P2021', 'P2022'].includes(error.code);
    }

    if (!(error instanceof Error)) {
      return false;
    }

    const message = error.message.toLowerCase();
    const touchesAuthStore =
      message.includes('auth_sessions') ||
      message.includes('auth_devices') ||
      message.includes('login_history');
    const indicatesSchemaDrift =
      message.includes('does not exist') ||
      message.includes('relation') ||
      message.includes('column') ||
      message.includes('table');

    return touchesAuthStore && indicatesSchemaDrift;
  }

  private async revokeSessionById(sessionId: string, reason: string) {
    await this.prisma.authSession.updateMany({
      where: {
        sessionId,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
        revokedReason: reason,
        isCurrent: false,
      },
    });
  }

  private getOwnerFromPrincipal(principal: ShieldPrincipal) {
    if (principal.customerId?.trim()) {
      return {
        ownerType: 'CUSTOMER',
        ownerId: principal.customerId.trim(),
        customerId: BigInt(principal.customerId.trim()),
        userId: null as bigint | null,
      };
    }

    if (principal.userId?.trim()) {
      return {
        ownerType: 'USER',
        ownerId: principal.userId.trim(),
        customerId: null as bigint | null,
        userId: BigInt(principal.userId.trim()),
      };
    }

    throw new UnauthorizedException('Principal does not own an auth session.');
  }

  private mapSessionToPrincipal(session: SessionRecord): ShieldPrincipal {
    const permissions = Array.isArray(session.permissions)
      ? session.permissions
          .map((entry) => String(entry))
          .filter((entry) => entry.trim().length > 0)
      : [];

    return {
      subjectId:
        session.subjectId,
      sessionId: session.sessionId,
      principalType: this.toPrincipalType(session.principalType),
      roleCode: session.roleCode ?? 'CUSTOMER',
      userType: this.toUserType(session.userType),
      accessScope: this.toAccessScope(session.accessScope, 'SELF'),
      permissions,
      firebaseUid: session.firebaseUid ?? '',
      authProvider: session.authProvider ?? '',
      customerId: session.customerId?.toString(),
      userId: session.userId?.toString(),
      email: session.email ?? undefined,
      mobile: session.mobile ?? undefined,
      branchBusinessId: session.branchBusinessId ?? undefined,
    };
  }

  private async rehydrateSessionPrincipal(
    session: SessionRecord,
  ): Promise<ShieldPrincipal> {
    if (session.userId != null) {
      const user = await this.prisma.user.findUnique({
        where: { id: session.userId },
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

      if (!user || user.deletedAt != null) {
        throw new UnauthorizedException(
          'Internal user is no longer provisioned in SHIELD.',
        );
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

      return {
        subjectId: session.subjectId,
        sessionId: session.sessionId,
        principalType: this.toPrincipalType(session.principalType),
        roleCode: user.role.code,
        userType: this.toUserType(user.userType ?? user.role.userType),
        accessScope: this.toAccessScope(
          user.accessScope ?? user.role.defaultScope,
          'BRANCH',
        ),
        permissions: this.mergeRolePermissions(
          user.role.code,
          user.role.rolePermissions
            .map((entry) => entry.permission.code)
            .filter((value): value is string => !!value),
        ),
        firebaseUid: user.firebaseUid ?? session.firebaseUid ?? '',
        authProvider: user.authProvider ?? session.authProvider ?? '',
        customerId: session.customerId?.toString(),
        userId: user.id.toString(),
        email: user.email ?? session.email ?? undefined,
        mobile: user.mobile ?? session.mobile ?? undefined,
        branchBusinessId:
          user.branchBusinessId?.toString() ??
          session.branchBusinessId ??
          undefined,
      };
    }

    if (session.customerId != null) {
      const customer = await this.prisma.customer.findUnique({
        where: { id: session.customerId },
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
        throw new UnauthorizedException('Customer is not provisioned in SHIELD.');
      }

      if (
        customer.status &&
        ['SUSPENDED', 'INACTIVE', 'DELETED'].includes(
          customer.status.toUpperCase(),
        )
      ) {
        throw new UnauthorizedException(
          `Customer status ${customer.status} is not allowed to sign in.`,
        );
      }

      return {
        subjectId: customer.uuid,
        sessionId: session.sessionId,
        principalType: 'CUSTOMER',
        roleCode: 'CUSTOMER',
        userType: 'CUSTOMER',
        accessScope: 'SELF',
        permissions: this.mergeRolePermissions('CUSTOMER', []),
        firebaseUid: customer.firebaseUid ?? session.firebaseUid ?? '',
        authProvider: session.authProvider ?? '',
        customerId: customer.id.toString(),
        userId: undefined,
        email: customer.email ?? undefined,
        mobile: customer.mobile ?? undefined,
        branchBusinessId: undefined,
      };
    }

    return this.mapSessionToPrincipal(session);
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

    return this.mergeRolePermissions(
      roleCode,
      role?.rolePermissions
        .map((entry) => entry.permission.code)
        .filter((value): value is string => !!value) ?? [],
    );
  }

  private mergeRolePermissions(roleCode: string, runtimePermissions: string[]) {
    return Array.from(new Set([...runtimePermissions, ...getRolePermissions(roleCode)]));
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

  private hashToken(value: string) {
    return createHash('sha256').update(value).digest('hex');
  }

  private buildDeviceFingerprint(requestContext?: AuthRequestContext) {
    const raw = [
      requestContext?.deviceId?.trim(),
      requestContext?.userAgent?.trim(),
      requestContext?.platform?.trim(),
      requestContext?.browser?.trim(),
      requestContext?.os?.trim(),
    ]
      .filter((value): value is string => Boolean(value && value.trim()))
      .join('|');

    return this.hashToken(raw || 'shield-unknown-device');
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

  private toPrincipalType(value: string | null | undefined): ShieldPrincipalType {
    return value === 'SYSTEM' || value === 'USER' ? value : 'CUSTOMER';
  }
}
