import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ServiceProviderService } from './service-provider.service';
import { ServiceProviderController } from './service-provider.controller';

@Module({
  imports: [PrismaModule],
  controllers: [ServiceProviderController],
  providers: [ServiceProviderService],
  exports: [ServiceProviderService],
})
export class ServiceProviderModule {}
