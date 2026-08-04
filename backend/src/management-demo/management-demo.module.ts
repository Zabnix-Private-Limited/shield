import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ManagementDemoController } from './management-demo.controller';
import { ManagementDemoService } from './management-demo.service';

@Module({
  imports: [PrismaModule],
  controllers: [ManagementDemoController],
  providers: [ManagementDemoService],
})
export class ManagementDemoModule {}
