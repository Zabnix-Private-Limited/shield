import { Module } from '@nestjs/common';
import { PlatformCapabilitiesModule } from '../platform-capabilities/platform-capabilities.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ProviderWorkspaceMetadataService } from '../operations-queue/provider-workspace-metadata.service';
import { PlatformMetadataController } from './platform-metadata.controller';
import { PlatformMetadataService } from './platform-metadata.service';

@Module({
  imports: [PrismaModule, PlatformCapabilitiesModule],
  controllers: [PlatformMetadataController],
  providers: [PlatformMetadataService, ProviderWorkspaceMetadataService],
  exports: [PlatformMetadataService],
})
export class PlatformMetadataModule {}
