import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { getAppEnv } from '../config/app-env';
import { AuthService } from './auth.service';
import { getRolePermissions } from './rbac-catalog';
import { IS_PUBLIC_ROUTE } from './public.decorator';

@Injectable()
export class ShieldJwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly authService: AuthService,
  ) {}

  async canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_ROUTE, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization?.toString() || '';
    const [scheme, token] = authHeader.split(' ');

    if ((!scheme || scheme !== 'Bearer' || !token) && this.shouldAllowDevCustomer(request)) {
      request.shieldPrincipal = this.buildDevCustomerPrincipal();
      return true;
    }

    if (scheme !== 'Bearer' || !token) {
      throw new UnauthorizedException('Bearer token is required.');
    }

    request.shieldPrincipal = await this.authService.verifyAccessToken(token);
    return true;
  }

  private shouldAllowDevCustomer(request: any) {
    const env = getAppEnv();
    if (env.nodeEnv !== 'development') {
      return false;
    }

    const origin = request.headers.origin?.toString() || '';
    const referer = request.headers.referer?.toString() || '';
    const host = request.headers.host?.toString() || '';
    const localMarkers = ['localhost', '127.0.0.1'];
    const isLocalRequest = [origin, referer, host].some((value) =>
      localMarkers.some((marker) => value.includes(marker)),
    );

    if (!isLocalRequest) {
      return false;
    }

    const method = request.method?.toString().toUpperCase() || 'GET';
    const path = request.path?.toString() || '';
    const allowedPathPrefixes = [
      '/customers/',
      '/wallets/',
      '/appointments',
      '/documents',
      '/notifications',
    ];

    return (
      ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'].includes(method) &&
      allowedPathPrefixes.some((prefix) => path.startsWith(prefix))
    );
  }

  private buildDevCustomerPrincipal() {
    return {
      subjectId: 'dev-customer-1',
      sessionId: 'dev-session-customer-1',
      principalType: 'CUSTOMER' as const,
      roleCode: 'CUSTOMER',
      userType: 'CUSTOMER' as const,
      accessScope: 'SELF' as const,
      permissions: getRolePermissions('CUSTOMER'),
      firebaseUid: 'dev-customer-1',
      authProvider: 'development-localhost',
      customerId: '1',
      mobile: 'dev-customer-1',
    };
  }
}
