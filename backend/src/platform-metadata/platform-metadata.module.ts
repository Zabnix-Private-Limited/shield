import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ProviderWorkspaceMetadataService } from '../operations-queue/provider-workspace-metadata.service';
import { PlatformMetadataController } from './platform-metadata.controller';
import { PlatformMetadataService } from './platform-metadata.service';

@Module({
  imports: [PrismaModule],
  controllers: [PlatformMetadataController],
  providers: [PlatformMetadataService, ProviderWorkspaceMetadataService],
  exports: [PlatformMetadataService],
})
export class PlatformMetadataModule {}
