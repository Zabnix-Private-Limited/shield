import './instrument';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { getAppEnv } from './config/app-env';
import {
  createImmediatePreflightHandler,
  createShieldCorsOptions,
} from './bootstrap/cors';

async function bootstrap() {
  const env = getAppEnv();
  const app = await NestFactory.create(AppModule);

  app.enableShutdownHooks();
  app.use(createImmediatePreflightHandler(env));
  app.enableCors(createShieldCorsOptions(env));
  await app.listen(env.port);
}
bootstrap();
