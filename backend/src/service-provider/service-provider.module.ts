import { Module } from '@nestjs/common';
import { AppointmentModule } from '../appointment/appointment.module';
import { CustomerModule } from '../customer/customer.module';
import { DocumentModule } from '../document/document.module';
import { NotificationModule } from '../notification/notification.module';
import { OperationsQueueModule } from '../operations-queue/operations-queue.module';
import { PharmacyModule } from '../pharmacy/pharmacy.module';
import { PrismaModule } from '../prisma/prisma.module';
import { TimelineModule } from '../timeline/timeline.module';
import { WalletModule } from '../wallet/wallet.module';
import { ServiceProviderService } from './service-provider.service';
import { ServiceProviderController } from './service-provider.controller';

@Module({
  imports: [
    PrismaModule,
    OperationsQueueModule,
    CustomerModule,
    WalletModule,
    AppointmentModule,
    DocumentModule,
    NotificationModule,
    PharmacyModule,
    TimelineModule,
  ],
  controllers: [ServiceProviderController],
  providers: [ServiceProviderService],
  exports: [ServiceProviderService],
})
export class ServiceProviderModule {}
