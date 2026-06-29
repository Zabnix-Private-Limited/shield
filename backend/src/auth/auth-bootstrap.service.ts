import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ensureRbacCatalog } from './rbac-seed';

@Injectable()
export class AuthBootstrapService {
  private readonly logger = new Logger(AuthBootstrapService.name);

  constructor(private readonly prisma: PrismaService) {}

  async ensureCatalog() {
    await ensureRbacCatalog(this.prisma);
    this.logger.log(
      'RBAC catalog ensured.',
    );
  }
}
