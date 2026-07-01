import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { PlatformCapabilitiesController } from './platform-capabilities.controller';
import { PlatformPrintService } from './platform-print.service';
import { PlatformRealtimeService } from './platform-realtime.service';
import { PlatformReportService } from './platform-report.service';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [PlatformCapabilitiesController],
  providers: [
    PlatformPrintService,
    PlatformRealtimeService,
    PlatformReportService,
  ],
  exports: [
    PlatformPrintService,
    PlatformRealtimeService,
    PlatformReportService,
  ],
})
export class PlatformCapabilitiesModule {}
