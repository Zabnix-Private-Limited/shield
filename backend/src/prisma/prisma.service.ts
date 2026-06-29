import 'dotenv/config';
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    const databaseUrl = normalizeDatabaseUrl(process.env.DATABASE_URL);
    const isDevelopment = process.env.NODE_ENV === 'development';
    const pool = new Pool({ connectionString: databaseUrl });
    const adapter = new PrismaPg(pool);
    super({
      adapter,
      log: isDevelopment ? ['query', 'info', 'warn', 'error'] : ['warn', 'error'],
    });
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}

function normalizeDatabaseUrl(databaseUrl?: string) {
  if (!databaseUrl?.trim()) {
    return databaseUrl;
  }

  const trimmed = databaseUrl.trim();
  let parsed: URL;

  try {
    parsed = new URL(trimmed);
  } catch {
    return trimmed;
  }

  const sslMode = parsed.searchParams.get('sslmode')?.toLowerCase();
  const hasCompatFlag = parsed.searchParams.has('uselibpqcompat');

  if (
    !hasCompatFlag &&
    sslMode != null &&
    ['prefer', 'require', 'verify-ca'].includes(sslMode)
  ) {
    // Preserve the current stricter behavior and silence the upcoming pg warning.
    parsed.searchParams.set('uselibpqcompat', 'true');
  }

  return parsed.toString();
}
