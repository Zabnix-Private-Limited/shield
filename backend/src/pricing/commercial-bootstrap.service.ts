import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { seedCommercialDefaults } from './commercial-seed';

@Injectable()
export class CommercialBootstrapService {
  private readonly logger = new Logger(CommercialBootstrapService.name);

  constructor(private readonly prisma: PrismaService) {}

  async ensureDefaults() {
    await seedCommercialDefaults(this.prisma);
    this.logger.log(
      'Commercial defaults ensured.',
    );
  }
}
