import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Req,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import { AuthService } from './auth.service';
import { CurrentPrincipal } from './current-principal.decorator';
import { Public } from './public.decorator';
import type { AuthRequestContext, ShieldPrincipal } from './auth.types';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('customer/login')
  async customerLogin(@Body() body: any, @Req() request: Request) {
    return {
      success: true,
      message: 'Customer login successful.',
      data: await this.authService.loginCustomer(
        body.firebase_id_token?.toString().trim() || '',
        this.extractRequestContext(request, body, 'PHONE_OTP'),
      ),
    };
  }

  @Public()
  @Post('customer/register')
  async customerRegister(@Body() body: any, @Req() request: Request) {
    return {
      success: true,
      message: 'Customer registration successful.',
      data: await this.authService.registerCustomer(
        body.firebase_id_token?.toString().trim() || '',
        body,
        this.extractRequestContext(request, body, 'PHONE_OTP'),
      ),
    };
  }

  @Public()
  @Post('internal/login')
  async internalLogin(@Body() body: any, @Req() request: Request) {
    return {
      success: true,
      message: 'Internal user login successful.',
      data: await this.authService.loginInternalUser(
        body.firebase_id_token?.toString().trim() || '',
        this.extractRequestContext(request, body, 'GOOGLE_SIGN_IN'),
      ),
    };
  }

  @Public()
  @Post('refresh')
  async refresh(@Body() body: any, @Req() request: Request) {
    return {
      success: true,
      message: 'Session refreshed successfully.',
      data: await this.authService.refresh(
        body.refresh_token?.toString().trim() || '',
        this.extractRequestContext(request, body, 'REFRESH_TOKEN'),
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

  @Get('sessions')
  async sessions(@CurrentPrincipal() principal?: ShieldPrincipal) {
    if (!principal) {
      throw new UnauthorizedException('Authenticated principal is missing.');
    }

    return {
      success: true,
      message: 'Authenticated sessions retrieved successfully.',
      data: await this.authService.listSessions(principal),
    };
  }

  @Get('login-history')
  async loginHistory(
    @CurrentPrincipal() principal?: ShieldPrincipal,
    @Query('limit') limit?: string,
  ) {
    if (!principal) {
      throw new UnauthorizedException('Authenticated principal is missing.');
    }

    return {
      success: true,
      message: 'Login history retrieved successfully.',
      data: await this.authService.listLoginHistory(
        principal,
        Number(limit ?? 20),
      ),
    };
  }

  @Post('sessions/:sessionId/revoke')
  async revokeSession(
    @Param('sessionId') sessionId: string,
    @CurrentPrincipal() principal?: ShieldPrincipal,
  ) {
    if (!principal) {
      throw new UnauthorizedException('Authenticated principal is missing.');
    }

    return {
      success: true,
      message: 'Session revoked successfully.',
      data: await this.authService.revokeOwnedSession(principal, sessionId),
    };
  }

  @Post('sessions/revoke-others')
  async revokeOtherSessions(@CurrentPrincipal() principal?: ShieldPrincipal) {
    if (!principal) {
      throw new UnauthorizedException('Authenticated principal is missing.');
    }

    return {
      success: true,
      message: 'Other sessions revoked successfully.',
      data: await this.authService.revokeOtherOwnedSessions(principal),
    };
  }

  private extractRequestContext(
    request: Request,
    body: any,
    loginMethod: string,
  ): AuthRequestContext {
    const userAgent = request.headers['user-agent']?.toString().trim();
    const forwardedFor = request.headers['x-forwarded-for']
      ?.toString()
      .split(',')[0]
      ?.trim();
    const browser = this.detectBrowser(userAgent);
    const platformHeader = this.cleanHeaderValue(
      request.headers['sec-ch-ua-platform']?.toString(),
    );
    const platform =
      body?.platform?.toString().trim() ||
      this.cleanHeaderValue(request.headers['x-shield-platform']?.toString()) ||
      platformHeader ||
      this.detectPlatform(userAgent);

    return {
      deviceId:
        body?.device_id?.toString().trim() ||
        this.cleanHeaderValue(request.headers['x-device-id']?.toString()),
      deviceName:
        body?.device_label?.toString().trim() ||
        this.cleanHeaderValue(request.headers['x-device-label']?.toString()) ||
        platform,
      platform,
      browser,
      os: this.detectOs(userAgent, platform),
      ipAddress: forwardedFor || request.ip,
      userAgent,
      loginMethod,
    };
  }

  private cleanHeaderValue(value?: string) {
    return value?.replaceAll('"', '').trim() || undefined;
  }

  private detectBrowser(userAgent?: string) {
    const ua = userAgent?.toLowerCase() ?? '';
    if (ua.includes('edg/')) {
      return 'EDGE';
    }
    if (ua.includes('chrome/')) {
      return 'CHROME';
    }
    if (ua.includes('safari/') && !ua.includes('chrome/')) {
      return 'SAFARI';
    }
    if (ua.includes('firefox/')) {
      return 'FIREFOX';
    }
    return 'UNKNOWN';
  }

  private detectPlatform(userAgent?: string) {
    const ua = userAgent?.toLowerCase() ?? '';
    if (ua.includes('android')) {
      return 'ANDROID';
    }
    if (ua.includes('iphone') || ua.includes('ipad') || ua.includes('ios')) {
      return 'IOS';
    }
    if (ua.includes('windows')) {
      return 'WINDOWS';
    }
    if (ua.includes('mac os')) {
      return 'MACOS';
    }
    if (ua.includes('linux')) {
      return 'LINUX';
    }
    return 'WEB';
  }

  private detectOs(userAgent?: string, platform?: string) {
    const ua = userAgent?.toLowerCase() ?? '';
    if (ua.includes('android')) {
      return 'ANDROID';
    }
    if (ua.includes('iphone') || ua.includes('ipad') || ua.includes('ios')) {
      return 'IOS';
    }
    if (ua.includes('windows')) {
      return 'WINDOWS';
    }
    if (ua.includes('mac os')) {
      return 'MACOS';
    }
    if (ua.includes('linux')) {
      return 'LINUX';
    }
    return platform ?? 'UNKNOWN';
  }
}
