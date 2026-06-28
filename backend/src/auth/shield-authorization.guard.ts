import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { REQUIRED_PERMISSIONS } from './permissions.decorator';
import { IS_PUBLIC_ROUTE } from './public.decorator';
import type { ShieldPrincipal } from './auth.types';

@Injectable()
export class ShieldAuthorizationGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_ROUTE, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const requiredPermissions =
      this.reflector.getAllAndOverride<string[]>(REQUIRED_PERMISSIONS, [
        context.getHandler(),
        context.getClass(),
      ]) ?? [];

    if (requiredPermissions.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const principal = request.shieldPrincipal as ShieldPrincipal | undefined;
    if (!principal) {
      throw new ForbiddenException('Authenticated principal is missing.');
    }

    const grantedPermissions = new Set(principal.permissions);
    const missing = requiredPermissions.filter(
      (permission) => !grantedPermissions.has(permission),
    );

    if (missing.length > 0) {
      throw new ForbiddenException(
        `Missing required permissions: ${missing.join(', ')}`,
      );
    }

    return true;
  }
}
