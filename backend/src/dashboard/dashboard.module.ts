import { Module } from '@nestjs/common';
import { CustomerDashboardController } from './customer-dashboard.controller';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';
import { PrismaModule } from '../prisma/prisma.module';
import { WalletModule } from '../wallet/wallet.module';

@Module({
  imports: [PrismaModule, WalletModule],
  controllers: [DashboardController, CustomerDashboardController],
  providers: [DashboardService],
  exports: [DashboardService],
})
export class DashboardModule {}
