import { Module } from '@nestjs/common';
import { APP_FILTER, APP_INTERCEPTOR } from '@nestjs/core';
import { SentryModule, SentryGlobalFilter } from '@sentry/nestjs/setup';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
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
import { StorageModule } from './storage/storage.module';
import { SupportModule } from './support/support.module';
import { RedisModule } from './redis/redis.module';
import { AuthModule } from './auth/auth.module';
import { PricingModule } from './pricing/pricing.module';
import { ReferralModule } from './referral/referral.module';
import { MasterDataModule } from './master-data/master-data.module';
import { OperationsQueueModule } from './operations-queue/operations-queue.module';
import { PlatformMetadataModule } from './platform-metadata/platform-metadata.module';
import { ServiceProviderModule } from './service-provider/service-provider.module';
import { TimelineModule } from './timeline/timeline.module';
import { PlatformCapabilitiesModule } from './platform-capabilities/platform-capabilities.module';

@Module({
  imports: [
    SentryModule.forRoot(),
    AuthModule,
    MasterDataModule,
    PlatformMetadataModule,
    PlatformCapabilitiesModule,
    OperationsQueueModule,
    ServiceProviderModule,
    TimelineModule,
    PrismaModule,
    PricingModule,
    ReferralModule,
    CustomerModule,
    WalletModule,
    CreditModule,
    AppointmentModule,
    DocumentModule,
    CrmModule,
    NotificationModule,
    DashboardModule,
    PharmacyModule,
    StorageModule,
    SupportModule,
    RedisModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_INTERCEPTOR,
      useClass: BigIntInterceptor,
    },
    {
      provide: APP_FILTER,
      useClass: SentryGlobalFilter,
    },
  ],
})
export class AppModule {}
