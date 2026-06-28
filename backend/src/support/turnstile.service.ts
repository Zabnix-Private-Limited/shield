import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { getAppEnv } from '../config/app-env';

type TurnstileVerifyResult = {
  success: boolean;
  challenge_ts?: string;
  hostname?: string;
  'error-codes'?: string[];
  action?: string;
  cdata?: string;
};

@Injectable()
export class TurnstileService {
  private readonly logger = new Logger(TurnstileService.name);
  private readonly env = getAppEnv();

  isConfigured() {
    return this.env.turnstileSecretKey.trim().length > 0;
  }

  async verifyToken(token: string, remoteIp?: string) {
    if (!this.isConfigured()) {
      return {
        success: true,
        skipped: true,
      };
    }

    const params = new URLSearchParams({
      secret: this.env.turnstileSecretKey.trim(),
      response: token.trim(),
    });

    const normalizedIp = remoteIp?.trim() ?? '';
    if (normalizedIp.length > 0) {
      params.set('remoteip', normalizedIp);
    }

    const response = await fetch(
      'https://challenges.cloudflare.com/turnstile/v0/siteverify',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      },
    );

    if (!response.ok) {
      this.logger.warn(
        `Turnstile siteverify returned HTTP ${response.status}.`,
      );
      throw new BadRequestException(
        'Turnstile verification could not be completed.',
      );
    }

    const result = (await response.json()) as TurnstileVerifyResult;
    return {
      success: result.success,
      skipped: false,
      hostname: result.hostname,
      action: result.action,
      errors: result['error-codes'] ?? [],
    };
  }

  async assertValidToken(token: string, remoteIp?: string) {
    if (!token.trim()) {
      throw new BadRequestException(
        'Turnstile verification token is required.',
      );
    }

    const result = await this.verifyToken(token, remoteIp);
    if (!result.success) {
      this.logger.warn(
        `Turnstile rejected a submission. Errors: ${(result.errors ?? []).join(', ') || 'unknown'}.`,
      );
      throw new BadRequestException('Verification failed. Please try again.');
    }

    return result;
  }
}
