import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

@Injectable()
export class WalletService {
  constructor(private prisma: PrismaService) {}

  async getWalletByCustomerId(customerId: bigint) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { customerId },
    });
    if (!wallet) {
      throw new NotFoundException(`Wallet not found for customer ID ${customerId}`);
    }

    const creditAccount = await this.prisma.creditAccount.findUnique({
      where: { customerId },
    });

    const balance = await this.calculateBalance(wallet.id);

    return {
      walletId: wallet.id,
      customerId: wallet.customerId,
      balance,
      credit_available: creditAccount ? Number(creditAccount.availableCredit) : 0,
      status: wallet.status,
    };
  }

  async calculateBalance(walletId: bigint): Promise<number> {
    const txns = await this.prisma.walletTransaction.findMany({
      where: { walletId },
    });

    let balance = 0;
    for (const txn of txns) {
      const amount = Number(txn.amount || 0);
      const type = (txn.transactionType || '').toUpperCase();

      if (['CREDIT', 'RECHARGE', 'OPENING_BALANCE', 'PROMOTIONAL_CREDIT'].includes(type)) {
        balance += amount;
      } else if (['DEBIT', 'PURCHASE', 'ADJUSTMENT', 'REVERSAL'].includes(type)) {
        balance -= amount;
      }
    }

    return balance;
  }

  async recharge(customerId: bigint, amount: number, staffUserId?: bigint, remarks?: string) {
    const wallet = await this.prisma.wallet.findUnique({ where: { customerId } });
    if (!wallet) {
      throw new NotFoundException(`Wallet not found for customer ID ${customerId}`);
    }

    return this.prisma.walletTransaction.create({
      data: {
        uuid: randomUUID(),
        walletId: wallet.id,
        transactionType: 'CREDIT',
        amount,
        remarks: remarks || 'Wallet recharge',
        createdBy: staffUserId,
      },
    });
  }

  async adjust(customerId: bigint, amount: number, type: 'CREDIT' | 'DEBIT', staffUserId?: bigint, remarks?: string) {
    const wallet = await this.prisma.wallet.findUnique({ where: { customerId } });
    if (!wallet) {
      throw new NotFoundException(`Wallet not found for customer ID ${customerId}`);
    }

    return this.prisma.walletTransaction.create({
      data: {
        uuid: randomUUID(),
        walletId: wallet.id,
        transactionType: type,
        amount,
        remarks: remarks || `Manual wallet adjustment (${type})`,
        createdBy: staffUserId,
      },
    });
  }

  async getTransactions(walletId: bigint, filters: { from?: string; to?: string; type?: string }) {
    const whereClause: any = { walletId };

    if (filters.type) {
      whereClause.transactionType = filters.type.toUpperCase();
    }

    if (filters.from || filters.to) {
      whereClause.createdAt = {};
      if (filters.from) {
        whereClause.createdAt.gte = new Date(filters.from);
      }
      if (filters.to) {
        whereClause.createdAt.lte = new Date(filters.to);
      }
    }

    return this.prisma.walletTransaction.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
    });
  }
}
