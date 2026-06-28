import './instrument';
import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { getAppEnv } from './config/app-env';
import express from 'express';

const expressApp = express();

async function createApp() {
  const env = getAppEnv();
  const app = await NestFactory.create(AppModule, new ExpressAdapter(expressApp));
  app.enableShutdownHooks();
  app.enableCors({
    origin: env.corsOrigins,
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
  });
  await app.init();
  return app;
}

// Serverless export for Vercel
let appReady: ReturnType<typeof createApp> | null = null;

async function getReadyApp() {
  if (!appReady) {
    appReady = createApp();
  }
  return appReady;
}

// Standard HTTP server for local dev and non-serverless environments
if (process.env.VERCEL !== '1') {
  (async () => {
    const env = getAppEnv();
    const app = await NestFactory.create(AppModule);
    app.enableShutdownHooks();
    app.enableCors({
      origin: env.corsOrigins,
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
    });
    await app.listen(env.port);
  })();
}

// Vercel serverless handler export
export default async function handler(req: express.Request, res: express.Response) {
  await getReadyApp();
  expressApp(req, res);
}
