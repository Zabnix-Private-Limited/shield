import { Injectable } from '@nestjs/common';
import { RedisService } from './redis/redis.service';

@Injectable()
export class AppService {
  constructor(private readonly redisService: RedisService) {}

  getHello(): string {
    return 'Hello World!';
  }

  async getHealth() {
    const redis = await this.redisService.ping().catch((error: Error) => ({
      configured: this.redisService.isConfigured(),
      healthy: false,
      message: error.message,
    }));

    return {
      success: true,
      message: 'SHIELD backend health retrieved successfully',
      data: {
        status: 'ok',
        timestamp: new Date().toISOString(),
        services: {
          api: {
            healthy: true,
          },
          redis,
        },
      },
    };
  }
}
