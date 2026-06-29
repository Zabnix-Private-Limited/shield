import './instrument';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { getAppEnv } from './config/app-env';

async function bootstrap() {
  const env = getAppEnv();
  const app = await NestFactory.create(AppModule);
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
  await app.listen(env.port);
}
bootstrap();
