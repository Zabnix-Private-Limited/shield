import {
  Body,
  Controller,
  Get,
  Post,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { CurrentPrincipal } from './current-principal.decorator';
import { Public } from './public.decorator';
import type { ShieldPrincipal } from './auth.types';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('customer/login')
  async customerLogin(@Body() body: any) {
    return {
      success: true,
      message: 'Customer login successful.',
      data: await this.authService.loginCustomer(
        body.firebase_id_token?.toString().trim() || '',
      ),
    };
  }

  @Public()
  @Post('internal/login')
  async internalLogin(@Body() body: any) {
    return {
      success: true,
      message: 'Internal user login successful.',
      data: await this.authService.loginInternalUser(
        body.firebase_id_token?.toString().trim() || '',
      ),
    };
  }

  @Public()
  @Post('refresh')
  async refresh(@Body() body: any) {
    return {
      success: true,
      message: 'Session refreshed successfully.',
      data: await this.authService.refresh(
        body.refresh_token?.toString().trim() || '',
      ),
    };
  }

  @Post('logout')
  async logout(
    @Body() body: any,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    await this.authService.logout(
      body.refresh_token?.toString().trim() || undefined,
      principal,
    );

    return {
      success: true,
      message: 'Session logged out successfully.',
    };
  }

  @Get('me')
  async me(@CurrentPrincipal() principal?: ShieldPrincipal) {
    if (!principal) {
      throw new UnauthorizedException('Authenticated principal is missing.');
    }

    return {
      success: true,
      message: 'Authenticated profile retrieved successfully.',
      data: await this.authService.getProfile(principal),
    };
  }
}
