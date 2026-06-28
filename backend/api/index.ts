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
}

bootstrap();

export default expressApp;
