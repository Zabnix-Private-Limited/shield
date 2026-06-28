import './instrument';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { getAppEnv } from './config/app-env';

async function bootstrap() {
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
}
bootstrap();
