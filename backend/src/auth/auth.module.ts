import { Global, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { getAppEnv } from '../config/app-env';
import { CustomerModule } from '../customer/customer.module';
import { NotificationModule } from '../notification/notification.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { ProviderScopeService } from './provider-scope.service';
import { ShieldAuthorizationGuard } from './shield-authorization.guard';
import { ShieldJwtAuthGuard } from './shield-jwt-auth.guard';

@Global()
@Module({
  imports: [
    JwtModule.register({
      secret: getAppEnv().jwtAccessSecret,
    }),
    PrismaModule,
    CustomerModule,
    NotificationModule,
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    ProviderScopeService,
    {
      provide: APP_GUARD,
      useClass: ShieldJwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: ShieldAuthorizationGuard,
    },
  ],
  exports: [AuthService, ProviderScopeService],
})
export class AuthModule {}
