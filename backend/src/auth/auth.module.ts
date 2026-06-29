import { Global, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { getAppEnv } from '../config/app-env';
import { RedisModule } from '../redis/redis.module';
import { NotificationModule } from '../notification/notification.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { ShieldAuthorizationGuard } from './shield-authorization.guard';
import { ShieldJwtAuthGuard } from './shield-jwt-auth.guard';

@Global()
@Module({
  imports: [
    JwtModule.register({
      secret: getAppEnv().jwtAccessSecret,
    }),
    RedisModule,
    NotificationModule,
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    {
      provide: APP_GUARD,
      useClass: ShieldJwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: ShieldAuthorizationGuard,
    },
  ],
  exports: [AuthService],
})
export class AuthModule {}
