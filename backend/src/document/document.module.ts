import { Module } from '@nestjs/common';
import { DocumentController } from './document.controller';
import { DocumentService } from './document.service';
import { PrescriptionIntelligenceService } from './prescription-intelligence.service';
import { PrismaModule } from '../prisma/prisma.module';
import { StorageModule } from '../storage/storage.module';

@Module({
  imports: [PrismaModule, StorageModule],
  controllers: [DocumentController],
  providers: [DocumentService, PrescriptionIntelligenceService],
  exports: [DocumentService],
})
export class DocumentModule {}
