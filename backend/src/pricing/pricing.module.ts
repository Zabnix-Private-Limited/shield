import { Global, Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { CommercialBootstrapService } from './commercial-bootstrap.service';
import { PricingController } from './pricing.controller';
import { PricingService } from './pricing.service';

@Global()
@Module({
  imports: [PrismaModule],
  controllers: [PricingController],
  providers: [CommercialBootstrapService, PricingService],
  exports: [PricingService],
})
export class PricingModule {}
