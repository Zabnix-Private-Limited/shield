export const COMMISSION_SPLITS: Record<string, Record<string, number>> = {
  NATIONAL: { RESERVE: 40, NATIONAL: 60 },
  REGIONAL: { RESERVE: 30, NATIONAL: 10, REGIONAL: 60 },
  STATE: { RESERVE: 24, NATIONAL: 6, REGIONAL: 10, STATE: 60 },
  DISTRICT: { RESERVE: 19, NATIONAL: 5, REGIONAL: 6, STATE: 10, DISTRICT: 60 },
  ASSEMBLY: {
    RESERVE: 15,
    NATIONAL: 4,
    REGIONAL: 5,
    STATE: 6,
    DISTRICT: 10,
    ASSEMBLY: 60,
  },
  LSGD: {
    RESERVE: 12,
    NATIONAL: 3,
    REGIONAL: 4,
    STATE: 5,
    DISTRICT: 6,
    ASSEMBLY: 10,
    LSGD: 60,
  },
  WARD: {
    RESERVE: 10,
    NATIONAL: 2,
    REGIONAL: 3,
    STATE: 4,
    DISTRICT: 5,
    ASSEMBLY: 6,
    LSGD: 10,
    WARD: 60,
  },
};

export function monthlySubscriptionAllocations(totalPaise: bigint): bigint[] {
  if (totalPaise < 0n) throw new Error('Total entitlement cannot be negative.');
  const base = totalPaise / 12n;
  const remainder = totalPaise % 12n;
  return Array.from(
    { length: 12 },
    (_, index) => base + (BigInt(index) < remainder ? 1n : 0n),
  );
}

export function commissionBreakdown(
  poolPaise: bigint,
  originatingLevel: string,
) {
  const split = COMMISSION_SPLITS[originatingLevel.trim().toUpperCase()];
  if (!split) throw new Error('Unsupported originating commission level.');
  const rows = Object.entries(split).map(([recipientLevel, percentage]) => ({
    recipientLevel,
    percentage,
    amountPaise: (poolPaise * BigInt(percentage)) / 100n,
  }));
  const allocated = rows.reduce((sum, row) => sum + row.amountPaise, 0n);
  rows[0].amountPaise += poolPaise - allocated;
  return rows;
}
