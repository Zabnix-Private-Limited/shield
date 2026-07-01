import { Module } from '@nestjs/common';
import { AppointmentController } from './appointment.controller';
import { AppointmentService } from './appointment.service';
import { NotificationModule } from '../notification/notification.module';
import { PlatformCapabilitiesModule } from '../platform-capabilities/platform-capabilities.module';
import { PrismaModule } from '../prisma/prisma.module';
import { TimelineModule } from '../timeline/timeline.module';
import { WalletModule } from '../wallet/wallet.module';

@Module({
  imports: [
    PrismaModule,
    WalletModule,
    TimelineModule,
    NotificationModule,
    PlatformCapabilitiesModule,
  ],
  controllers: [AppointmentController],
  providers: [AppointmentService],
  exports: [AppointmentService],
})
export class AppointmentModule {}
