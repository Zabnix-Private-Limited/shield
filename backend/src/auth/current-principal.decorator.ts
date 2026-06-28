import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { ShieldPrincipal } from './auth.types';

export const CurrentPrincipal = createParamDecorator(
  (_data: unknown, context: ExecutionContext): ShieldPrincipal | undefined => {
    const request = context.switchToHttp().getRequest();
    return request.shieldPrincipal as ShieldPrincipal | undefined;
  },
);
