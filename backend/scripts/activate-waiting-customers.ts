import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { randomUUID } from 'crypto';

const apply = process.argv.includes('--apply');
const dryRun = !apply || process.argv.includes('--dry-run');
const allowedStatuses = ['PENDING', 'WAITING', 'PENDING_APPROVAL'];

if (process.env.SHIELD_DATA_FIX_ENV !== 'non-production') {
  throw new Error('Refusing to connect: set SHIELD_DATA_FIX_ENV=non-production after independently verifying the database.');
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

async function main() {
  const candidates = await prisma.customer.findMany({
    where: { status: { in: allowedStatuses }, deletedAt: null },
    include: { membership: { include: { membershipType: true } }, shieldCard: true },
  });
  const eligible = candidates.filter((customer) =>
    Boolean(customer.firstName?.trim() && customer.lastName?.trim() && customer.mobile?.trim() && customer.agentCode?.trim() &&
      customer.membership?.membershipNumber?.trim() && customer.membership.membershipType?.status === 'ACTIVE'),
  );
  const excluded = candidates.length - eligible.length;
  console.log(JSON.stringify({ mode: dryRun ? 'dry-run' : 'apply', candidates: candidates.length, eligible: eligible.length, excluded, alreadyActive: 0, activated: 0, failed: 0 }));
  if (dryRun) return;

  let activated = 0;
  let failed = 0;
  for (const candidate of eligible) {
    try {
      const changed = await prisma.$transaction(async (tx) => {
        const current = await tx.customer.findUnique({
          where: { id: candidate.id }, include: { membership: { include: { membershipType: true } }, shieldCard: true },
        });
        if (!current || current.deletedAt || !allowedStatuses.includes(current.status ?? '') || !current.membership ||
            !current.firstName?.trim() || !current.lastName?.trim() || !current.mobile?.trim() || !current.agentCode?.trim() ||
            !current.membership.membershipNumber?.trim() || current.membership.membershipType?.status !== 'ACTIVE') return false;
        const now = new Date();
        const activationDate = current.membership.activationDate ?? now;
        const expiryDate = current.membership.expiryDate ?? new Date(new Date(activationDate).setFullYear(new Date(activationDate).getFullYear() + 1));
        await tx.membership.update({ where: { id: current.membership.id }, data: { status: 'ACTIVE', activationDate, expiryDate } });
        if (current.shieldCard) await tx.shieldCard.update({ where: { id: current.shieldCard.id }, data: { status: 'ACTIVE' } });
        await tx.customer.update({ where: { id: current.id }, data: { status: 'ACTIVE' } });
        await tx.customerStatusHistory.create({ data: { uuid: randomUUID(), customerId: current.id, oldStatus: current.status, newStatus: 'ACTIVE', remarks: 'Controlled waiting-membership activation batch' } });
        await tx.auditLog.create({ data: { action: 'CUSTOMER_MEMBERSHIP_BATCH_ACTIVATED', entityType: 'customer', entityId: current.id, oldData: { customerStatus: current.status, membershipStatus: current.membership.status }, newData: { customerStatus: 'ACTIVE', membershipStatus: 'ACTIVE' }, deviceInfo: 'activate-waiting-customers.ts' } });
        return true;
      });
      if (changed) activated++;
    } catch { failed++; }
  }
  console.log(JSON.stringify({ mode: 'apply', candidates: candidates.length, eligible: eligible.length, excluded, alreadyActive: 0, activated, failed }));
}

main().finally(async () => { await prisma.$disconnect(); await pool.end(); });
