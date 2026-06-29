import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { OperationsQueueController } from './operations-queue.controller';
import { OperationsQueueService } from './operations-queue.service';

@Module({
  imports: [PrismaModule],
  controllers: [OperationsQueueController],
  providers: [OperationsQueueService],
  exports: [OperationsQueueService],
})
export class OperationsQueueModule {}
