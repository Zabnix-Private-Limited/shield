import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { CustomerModule } from './customer/customer.module';
import { WalletModule } from './wallet/wallet.module';
import { CreditModule } from './credit/credit.module';
import { AppointmentModule } from './appointment/appointment.module';
import { DocumentModule } from './document/document.module';
import { CrmModule } from './crm/crm.module';
import { NotificationModule } from './notification/notification.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { PharmacyModule } from './pharmacy/pharmacy.module';
import { BigIntInterceptor } from './common/interceptors/bigint.interceptor';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    CustomerModule,
    WalletModule,
    CreditModule,
    AppointmentModule,
    DocumentModule,
    CrmModule,
    NotificationModule,
    DashboardModule,
    PharmacyModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_INTERCEPTOR,
      useClass: BigIntInterceptor,
    },
  ],
})
export class AppModule {}

