import { Module } from '@nestjs/common';
import { AppointmentModule } from '../appointment/appointment.module';
import { CrmModule } from '../crm/crm.module';
import { CustomerModule } from '../customer/customer.module';
import { DocumentModule } from '../document/document.module';
import { NotificationModule } from '../notification/notification.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ReferralModule } from '../referral/referral.module';
import { WalletModule } from '../wallet/wallet.module';
import { AgentController } from './agent.controller';
import { AgentService } from './agent.service';

@Module({
  imports: [
    PrismaModule,
    CustomerModule,
    WalletModule,
    AppointmentModule,
    DocumentModule,
    NotificationModule,
    ReferralModule,
    CrmModule,
  ],
  controllers: [AgentController],
  providers: [AgentService],
  exports: [AgentService],
})
export class AgentModule {}
