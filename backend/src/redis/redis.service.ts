import {
  Injectable,
  Logger,
  OnApplicationShutdown,
  OnModuleInit,
} from '@nestjs/common';
import Redis from 'ioredis';
import { getAppEnv } from '../config/app-env';

@Injectable()
export class RedisService implements OnModuleInit, OnApplicationShutdown {
  private readonly logger = new Logger(RedisService.name);
  private readonly env = getAppEnv();
  private client: Redis | null = null;

  onModuleInit() {
    if (!this.isConfigured()) {
      this.logger.log(
        'REDIS_URL is not configured. Redis runtime is disabled.',
      );
      return;
    }

    this.client = new Redis(this.env.redisUrl, {
      lazyConnect: true,
      maxRetriesPerRequest: 1,
      enableReadyCheck: true,
      keyPrefix: this.env.redisPrefix,
      tls:
        this.env.redisTls || this.env.redisUrl.startsWith('rediss://')
          ? {}
          : undefined,
    });

    this.client.on('connect', () => {
      this.logger.log('Redis/Valkey client connected.');
    });

    this.client.on('error', (error) => {
      this.logger.warn(`Redis/Valkey client error: ${error.message}`);
    });
  }

  async onApplicationShutdown() {
    if (this.client) {
      await this.client.quit().catch(async () => {
        await this.client?.disconnect();
      });
      this.client = null;
    }
  }

  isConfigured() {
    return this.env.redisUrl.trim().length > 0;
  }

  private async ensureConnected() {
    if (!this.client) {
      return null;
    }

    if (this.client.status === 'wait') {
      await this.client.connect();
    }

    return this.client;
  }

  async ping() {
    const client = await this.ensureConnected();
    if (!client) {
      return {
        configured: false,
        healthy: false,
        message: 'REDIS_URL is not configured.',
        prefix: this.env.redisPrefix,
        defaultTtlSeconds: this.env.redisDefaultTtl,
      };
    }

    const result = await client.ping();
    return {
      configured: true,
      healthy: result === 'PONG',
      message: result,
      prefix: this.env.redisPrefix,
      tls: this.env.redisTls || this.env.redisUrl.startsWith('rediss://'),
      defaultTtlSeconds: this.env.redisDefaultTtl,
    };
  }

  async set(key: string, value: string, ttlSeconds?: number) {
    const client = await this.ensureConnected();
    if (!client) {
      throw new Error('Redis is not configured.');
    }

    const resolvedTtl =
      ttlSeconds && ttlSeconds > 0
        ? ttlSeconds
        : this.env.redisDefaultTtl > 0
          ? this.env.redisDefaultTtl
          : undefined;

    if (resolvedTtl) {
      await client.set(key, value, 'EX', resolvedTtl);
      return;
    }

    await client.set(key, value);
  }

  async get(key: string) {
    const client = await this.ensureConnected();
    if (!client) {
      throw new Error('Redis is not configured.');
    }

    return client.get(key);
  }

  async delete(key: string) {
    const client = await this.ensureConnected();
    if (!client) {
      throw new Error('Redis is not configured.');
    }

    await client.del(key);
  }
}
