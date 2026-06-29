import { Module } from '@nestjs/common';
import { CustomerWalletController } from './customer-wallet.controller';
import { WalletController } from './wallet.controller';
import { WalletService } from './wallet.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [WalletController, CustomerWalletController],
  providers: [WalletService],
  exports: [WalletService],
})
export class WalletModule {}
