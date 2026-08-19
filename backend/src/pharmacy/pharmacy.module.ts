import { Module } from '@nestjs/common';
import { PharmacyController } from './pharmacy.controller';
import { PharmacyService } from './pharmacy.service';
import { PharmacyPaymentDetailsService } from './pharmacy-payment-details.service';
import { PharmacyPaymentsService } from './pharmacy-payments.service';
import { PrismaModule } from '../prisma/prisma.module';
import { PricingModule } from '../pricing/pricing.module';
import { ReferralModule } from '../referral/referral.module';
import { WalletModule } from '../wallet/wallet.module';
import { StorageModule } from '../storage/storage.module';
import { TimelineModule } from '../timeline/timeline.module';
import { AuthModule } from '../auth/auth.module';
import { NotificationModule } from '../notification/notification.module';

@Module({
  imports: [
    PrismaModule,
    PricingModule,
    ReferralModule,
    WalletModule,
    StorageModule,
    TimelineModule,
    AuthModule,
    NotificationModule,
  ],
  controllers: [PharmacyController],
  providers: [
    PharmacyService,
    PharmacyPaymentDetailsService,
    PharmacyPaymentsService,
  ],
  exports: [
    PharmacyService,
    PharmacyPaymentDetailsService,
    PharmacyPaymentsService,
  ],
})
export class PharmacyModule {}
