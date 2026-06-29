import { Module } from '@nestjs/common';
import { OperationsQueueModule } from '../operations-queue/operations-queue.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ServiceProviderService } from './service-provider.service';
import { ServiceProviderController } from './service-provider.controller';

@Module({
  imports: [PrismaModule, OperationsQueueModule],
  controllers: [ServiceProviderController],
  providers: [ServiceProviderService],
  exports: [ServiceProviderService],
})
export class ServiceProviderModule {}
