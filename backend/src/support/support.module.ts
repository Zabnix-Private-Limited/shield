import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import {
  CustomerSupportController,
  SupportController,
} from './support.controller';
import { SupportService } from './support.service';
import { TurnstileService } from './turnstile.service';

@Module({
  imports: [PrismaModule],
  controllers: [SupportController, CustomerSupportController],
  providers: [SupportService, TurnstileService],
  exports: [TurnstileService],
})
export class SupportModule {}
