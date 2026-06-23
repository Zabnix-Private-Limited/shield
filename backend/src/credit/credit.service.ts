import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

@Injectable()
export class CreditService {
  constructor(private prisma: PrismaService) {}

  async getCreditAccount(id: bigint) {
    // Search first by customer ID, fallback to CreditAccount primary key ID
    let account = await this.prisma.creditAccount.findUnique({
      where: { customerId: id },
    });

    if (!account) {
      account = await this.prisma.creditAccount.findUnique({
        where: { id },
      });
    }

    if (!account) {
      throw new NotFoundException(`Credit account not found for ID ${id}`);
    }

    return account;
  }

  async getTransactions(accountId: bigint) {
    return this.prisma.creditTransaction.findMany({
      where: { creditAccountId: accountId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async approveLimitIncrease(id: bigint, amount: number, remarks?: string) {
    const account = await this.getCreditAccount(id);

    return this.prisma.$transaction(async (tx) => {
      // 1. Log transaction
      await tx.creditTransaction.create({
        data: {
          uuid: randomUUID(),
          creditAccountId: account.id,
          transactionType: 'LIMIT_INCREASE',
          amount,
          remarks: remarks || `Credit limit increased by ₹${amount}`,
        },
      });

      // 2. Update limits
      const newLimit = Number(account.creditLimit || 0) + amount;
      const newAvailable = Number(account.availableCredit || 0) + amount;

      return tx.creditAccount.update({
        where: { id: account.id },
        data: {
          creditLimit: newLimit,
          availableCredit: newAvailable,
        },
      });
    });
  }
}
