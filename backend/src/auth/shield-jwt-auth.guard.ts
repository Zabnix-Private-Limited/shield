import {
  CanActivate,
  ExecutionContext,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthService } from './auth.service';
import { IS_PUBLIC_ROUTE } from './public.decorator';
import { RBAC_ROLES } from './rbac-catalog';
import type { ShieldPrincipal } from './auth.types';

const MOCK_BYPASS_PRINCIPAL: ShieldPrincipal = {
  subjectId: '00000000-0000-0000-0000-000000000001',
  sessionId: 'mock-bypass-session-001',
  principalType: 'USER',
  userId: '1',
  email: 'admin@shield.local',
  firebaseUid: 'mock-bypass-firebase-uid',
  authProvider: 'google.com',
  roleCode: 'ADMIN',
  userType: 'EMPLOYEE',
  accessScope: 'GLOBAL',
  permissions: RBAC_ROLES.find((r) => r.code === 'ADMIN')?.permissions ?? [],
};

@Injectable()
export class ShieldJwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly authService: AuthService,
  ) {}

  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest();

    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_ROUTE, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const authHeader = request.headers.authorization?.toString() || '';
    const [scheme, token] = authHeader.split(' ');

    if (scheme === 'Bearer' && token) {
      try {
        request.shieldPrincipal = await this.authService.verifyAccessToken(token);
        return true;
      } catch {
        // Fallback to bypass principal in dev mode
      }
    }

    // PRODUCTION CODE (UNCOMMENT FOR STRICT PROD AUTH):
    // if (scheme !== 'Bearer' || !token) {
    //   throw new UnauthorizedException('Bearer token is required.');
    // }
    // request.shieldPrincipal = await this.authService.verifyAccessToken(token);
    // return true;

    // DEV BYPASS MODE: Default mock admin principal when unauthenticated on localhost
    request.shieldPrincipal = MOCK_BYPASS_PRINCIPAL;
    return true;
  }
}
