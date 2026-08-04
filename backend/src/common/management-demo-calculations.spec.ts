import {
  commissionBreakdown,
  monthlySubscriptionAllocations,
} from './management-demo-calculations';

describe('management demo calculations', () => {
  it('keeps the annual plan entitlement exact in paise', () => {
    const allocations = monthlySubscriptionAllocations(1100000n);
    expect(allocations).toHaveLength(12);
    expect(allocations.reduce((sum, amount) => sum + amount, 0n)).toBe(
      1100000n,
    );
    expect(allocations[0]).toBe(91667n);
    expect(allocations[11]).toBe(91666n);
  });

  it('splits a ward commission pool exactly once', () => {
    const rows = commissionBreakdown(100000n, 'WARD');
    expect(rows.reduce((sum, row) => sum + row.amountPaise, 0n)).toBe(100000n);
    expect(rows.find((row) => row.recipientLevel === 'WARD')?.amountPaise).toBe(
      60000n,
    );
    expect(
      rows.find((row) => row.recipientLevel === 'RESERVE')?.amountPaise,
    ).toBe(10000n);
  });
});
