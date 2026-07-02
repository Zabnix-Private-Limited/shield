import '../src/instrument';
import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import { AppModule } from '../src/app.module';
import { getAppEnv } from '../src/config/app-env';
import {
  createImmediatePreflightHandler,
  createShieldCorsOptions,
} from '../src/bootstrap/cors';
import express from 'express';

const expressApp = express();
const env = getAppEnv();
let bootstrapPromise: Promise<void> | null = null;

expressApp.use(createImmediatePreflightHandler(env));

async function bootstrap() {
  const app = await NestFactory.create(AppModule, new ExpressAdapter(expressApp));
  app.enableShutdownHooks();
  app.use(createImmediatePreflightHandler(env));
  app.enableCors(createShieldCorsOptions(env));
  await app.init();
}

function ensureBootstrapped() {
  bootstrapPromise ??= bootstrap();
  return bootstrapPromise;
}

export default async function handler(req: express.Request, res: express.Response) {
  if (req.method.toUpperCase() === 'OPTIONS') {
    return expressApp(req, res);
  }

  await ensureBootstrapped();
  return expressApp(req, res);
}
