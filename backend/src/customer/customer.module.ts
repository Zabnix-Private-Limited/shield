import { Module } from '@nestjs/common';
import { CustomerController } from './customer.controller';
import { CustomerAccountController } from './customer-account.controller';
import { CustomerMembershipController } from './customer-membership.controller';
import { StoreChangeController } from './store-change.controller';
import { CustomerService } from './customer.service';
import { PrismaModule } from '../prisma/prisma.module';
import { ReferralModule } from '../referral/referral.module';
import { WalletModule } from '../wallet/wallet.module';

@Module({
  imports: [PrismaModule, ReferralModule, WalletModule],
  controllers: [
    CustomerController,
    CustomerMembershipController,
    CustomerAccountController,
    StoreChangeController,
  ],
  providers: [CustomerService],
  exports: [CustomerService],
})
export class CustomerModule {}
