import { Module } from '@nestjs/common';
import { CustomerModule } from '../customer/customer.module';
import { NotificationModule } from '../notification/notification.module';
import { PlatformCapabilitiesModule } from '../platform-capabilities/platform-capabilities.module';
import { PricingModule } from '../pricing/pricing.module';
import { PrismaModule } from '../prisma/prisma.module';
import { RedisModule } from '../redis/redis.module';
import { TimelineModule } from '../timeline/timeline.module';
import { WalletModule } from '../wallet/wallet.module';
import { AdminGovernanceController } from './admin-governance.controller';
import { AdminGovernanceService } from './admin-governance.service';

@Module({
  imports: [
    PrismaModule,
    PricingModule,
    CustomerModule,
    NotificationModule,
    PlatformCapabilitiesModule,
    TimelineModule,
    RedisModule,
    WalletModule,
  ],
  controllers: [AdminGovernanceController],
  providers: [AdminGovernanceService],
})
export class AdminGovernanceModule {}
