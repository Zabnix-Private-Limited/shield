import '../src/instrument';
import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import { AppModule } from '../src/app.module';
import { getAppEnv } from '../src/config/app-env';
import express from 'express';

const expressApp = express();

async function bootstrap() {
  const env = getAppEnv();
  const app = await NestFactory.create(AppModule, new ExpressAdapter(expressApp));
  const allowedOrigins = new Set<string>(
    [
      ...env.corsOrigins,
      env.appUrl,
    ]
      .map((value) => {
        try {
          return new URL(value).origin;
        } catch (_) {
          return value.trim();
        }
      })
      .filter(Boolean),
  );

  const isAllowedOrigin = (origin?: string) => {
    if (!origin || origin === 'null') {
      return true;
    }

    if (allowedOrigins.has(origin)) {
      return true;
    }

    try {
      const uri = new URL(origin);
      const hostname = uri.hostname.toLowerCase();
      return (
        uri.protocol === 'https:' &&
        hostname.endsWith('.vercel.app') &&
        hostname.startsWith('shield-')
      );
    } catch (_) {
      return false;
    }
  };

  app.enableShutdownHooks();
  app.enableCors({
    origin: (
      origin: string | undefined,
      callback: (error: Error | null, allow?: boolean) => void,
    ) => {
      if (isAllowedOrigin(origin)) {
        callback(null, true);
        return;
      }
      callback(new Error(`Origin not allowed by CORS: ${origin}`), false);
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'x-role',
      'sentry-trace',
      'baggage',
      'accept',
      'origin',
      'x-requested-with',
    ],
    credentials: true,
  });
  await app.init();
}

bootstrap();

export default expressApp;
