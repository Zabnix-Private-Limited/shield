import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';
import {
  WALLET_LEDGER_TYPES,
  WalletLedgerType,
} from '../pricing/pricing.types';

type WalletViewOptions = {
  includeHiddenBenefit?: boolean;
};

@Injectable()
export class WalletService {
  constructor(private readonly prisma: PrismaService) {}

  async walletBelongsToCustomer(walletId: bigint, customerId: bigint) {
    return (
      (await this.prisma.wallet.count({
        where: { id: walletId, customerId },
      })) > 0
    );
  }

  async getWalletByCustomerId(
    customerId: bigint,
    options: WalletViewOptions = {},
  ) {
    const wallet = await this.requireWallet(customerId);
    const creditAccount = await this.prisma.creditAccount.findUnique({
      where: { customerId },
    });
    const summary = await this.getWalletSummary(wallet.id);

    return {
      walletId: wallet.id,
      customerId: wallet.customerId,
      status: wallet.status,
      cashWallet: summary.cashWallet,
      rewardPoints: summary.rewardPoints,
      ...(options.includeHiddenBenefit
        ? {
            shieldBenefitLedger: summary.shieldBenefit,
          }
        : {}),
      creditAvailable: creditAccount
        ? Number(creditAccount.availableCredit)
        : 0,
    };
  }

  async getCustomerWalletBundle(customerId: bigint) {
    const customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
      include: {
        membership: {
          include: {
            membershipType: true,
          },
        },
        creditAccount: true,
      },
    });
    if (!customer) {
      throw new NotFoundException(`Customer with ID ${customerId} not found`);
    }

    const wallet = await this.requireWallet(customerId);
    const [summary, transactions] = await Promise.all([
      this.getWalletSummary(wallet.id),
      this.getTransactions(wallet.id, {}),
    ]);

    const monthlySpend = transactions.reduce((sum, txn) => {
      if (
        txn.ledger?.toUpperCase() !== WALLET_LEDGER_TYPES.CASH ||
        this.isPositiveCashEntry(txn.transactionType)
      ) {
        return sum;
      }
      return sum + Number(txn.amount || 0);
    }, 0);

    const rewardCredits = transactions.reduce((sum, txn) => {
      if (
        txn.ledger?.toUpperCase() !== WALLET_LEDGER_TYPES.REWARD_POINTS ||
        !this.isPositiveRewardEntry(txn.transactionType)
      ) {
        return sum;
      }
      return sum + Number(txn.amount || 0);
    }, 0);

    return {
      walletId: wallet.id.toString(),
      customerId: customer.id.toString(),
      status: wallet.status,
      cashWallet: {
        available: summary.cashWallet.available,
        credited: summary.cashWallet.credited,
        debited: summary.cashWallet.debited,
      },
      rewardPoints: {
        available: summary.rewardPoints.available,
        earned: summary.rewardPoints.earned,
        redeemed: summary.rewardPoints.redeemed,
      },
      benefitSummary: {
        benefitsUsed: summary.shieldBenefit.appliedTotal,
        grantedTotal: summary.shieldBenefit.granted,
        appliedTotal: summary.shieldBenefit.appliedTotal,
        hiddenRemaining: summary.shieldBenefit.remaining,
      },
      recentTransactions: transactions.map((txn) => ({
        id: txn.id.toString(),
        uuid: `wallet-txn-${txn.id.toString()}`,
        wallet_id: wallet.id.toString(),
        transaction_type: txn.transactionType,
        sub_ledger_type: txn.ledger,
        amount: Number(txn.amount || 0),
        reference_type: txn.referenceType,
        reference_id: txn.referenceId?.toString(),
        remarks: txn.remarks,
        created_at: txn.createdAt,
      })),
      statistics: {
        monthlySpend: Number(monthlySpend.toFixed(2)),
        rewardCredits: Number(rewardCredits.toFixed(2)),
        creditAvailable: customer.creditAccount
          ? Number(customer.creditAccount.availableCredit)
          : 0,
      },
      membership: customer.membership
        ? {
            id: customer.membership.id.toString(),
            uuid: customer.membership.uuid,
            membershipNumber: customer.membership.membershipNumber,
            status: customer.membership.status,
            activationDate: customer.membership.activationDate,
            expiryDate: customer.membership.expiryDate,
            membershipType: customer.membership.membershipType
              ? {
                  id: customer.membership.membershipType.id.toString(),
                  uuid: customer.membership.membershipType.uuid,
                  code: customer.membership.membershipType.code,
                  name: customer.membership.membershipType.name,
                }
              : null,
          }
        : null,
    };
  }

  async recharge(
    customerId: bigint,
    amount: number,
    staffUserId?: bigint,
    remarks?: string,
    ledgerType: WalletLedgerType = WALLET_LEDGER_TYPES.CASH,
  ) {
    const wallet = await this.requireWallet(customerId);
    const normalizedAmount = this.assertPositiveAmount(amount);

    if (ledgerType === WALLET_LEDGER_TYPES.REWARD_POINTS) {
      return this.prisma.rewardPointTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: wallet.id,
          transactionType: 'BONUS',
          actionCode: 'MANUAL_REWARD_CREDIT',
          points: normalizedAmount,
          reason: remarks || 'Manual reward points credit',
          createdBy: staffUserId,
          approvedBy: staffUserId,
          approvedAt: new Date(),
          status: 'APPROVED',
        },
      });
    }

    if (ledgerType === WALLET_LEDGER_TYPES.SHIELD_BENEFIT) {
      return this.prisma.benefitLedgerTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: wallet.id,
          transactionType: 'GRANT',
          amount: normalizedAmount,
          remarks: remarks || 'SHIELD promotional benefit grant',
          createdBy: staffUserId,
        },
      });
    }

    return this.prisma.cashWalletTransaction.create({
      data: {
        uuid: randomUUID(),
        walletId: wallet.id,
        transactionType: 'RECHARGE',
        amount: normalizedAmount,
        remarks: remarks || 'Cash wallet recharge',
        createdBy: staffUserId,
      },
    });
  }

  async createRechargeIntent(
    customerId: bigint,
    amount: number,
    idempotencyKey: string,
  ) {
    const normalizedAmount = this.assertPositiveAmount(amount);
    const key = idempotencyKey.trim();
    if (!key) throw new BadRequestException('Idempotency key is required.');
    const existing = await this.prisma.walletRechargeIntent.findUnique({
      where: { idempotencyKey: key },
    });
    if (existing) {
      if (existing.customerId !== customerId || Number(existing.amount) !== normalizedAmount) {
        throw new BadRequestException('Idempotency key cannot be reused for another recharge.');
      }
      return existing;
    }
    const wallet = await this.requireWallet(customerId);
    return this.prisma.walletRechargeIntent.create({
      data: { uuid: randomUUID(), customerId, walletId: wallet.id, amount: normalizedAmount, idempotencyKey: key, status: 'INITIATED' },
    });
  }

  async listRechargeIntents(customerId: bigint) {
    return this.prisma.walletRechargeIntent.findMany({
      where: { customerId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    });
  }

  async adjust(
    customerId: bigint,
    amount: number,
    type: 'CREDIT' | 'DEBIT',
    staffUserId?: bigint,
    remarks?: string,
    ledgerType: WalletLedgerType = WALLET_LEDGER_TYPES.CASH,
  ) {
    const wallet = await this.requireWallet(customerId);
    const normalizedAmount = this.assertPositiveAmount(amount);

    if (ledgerType === WALLET_LEDGER_TYPES.REWARD_POINTS) {
      return this.prisma.rewardPointTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: wallet.id,
          transactionType: type === 'CREDIT' ? 'APPROVED_CREDIT' : 'REDEEMED',
          actionCode:
            type === 'CREDIT'
              ? 'MANUAL_REWARD_ADJUSTMENT'
              : 'MANUAL_REWARD_DEBIT',
          points: normalizedAmount,
          reason: remarks || `Manual reward points adjustment (${type})`,
          createdBy: staffUserId,
          approvedBy: staffUserId,
          approvedAt: new Date(),
          status: 'APPROVED',
        },
      });
    }

    if (ledgerType === WALLET_LEDGER_TYPES.SHIELD_BENEFIT) {
      return this.prisma.benefitLedgerTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: wallet.id,
          transactionType: type === 'CREDIT' ? 'GRANT' : 'APPLIED',
          amount: normalizedAmount,
          remarks: remarks || `Manual SHIELD benefit adjustment (${type})`,
          createdBy: staffUserId,
        },
      });
    }

    return this.prisma.cashWalletTransaction.create({
      data: {
        uuid: randomUUID(),
        walletId: wallet.id,
        transactionType: type,
        amount: normalizedAmount,
        remarks: remarks || `Manual cash wallet adjustment (${type})`,
        createdBy: staffUserId,
      },
    });
  }

  async redeemRewardPoints(
    customerId: bigint,
    requestedPoints: number,
    staffUserId?: bigint,
  ) {
    const wallet = await this.requireWallet(customerId);
    const redemptionRule = await this.prisma.rewardRedemptionRule.findFirst({
      where: { status: 'ACTIVE' },
      orderBy: { createdAt: 'asc' },
    });
    if (!redemptionRule) {
      throw new BadRequestException(
        'Reward redemption rule is not configured.',
      );
    }

    const summary = await this.getWalletSummary(wallet.id);
    const availablePoints = summary.rewardPoints.available;
    const normalizedPoints = this.assertPositiveAmount(requestedPoints);

    if (normalizedPoints > availablePoints) {
      throw new BadRequestException(
        'Insufficient reward points for redemption.',
      );
    }
    if (normalizedPoints < Number(redemptionRule.minimumPoints || 0)) {
      throw new BadRequestException(
        'Requested points are below the minimum redemption threshold.',
      );
    }

    const currentMonthStart = new Date();
    currentMonthStart.setDate(1);
    currentMonthStart.setHours(0, 0, 0, 0);
    const currentMonthRedeemed =
      await this.prisma.rewardPointTransaction.findMany({
        where: {
          walletId: wallet.id,
          transactionType: 'REDEEMED',
          createdAt: { gte: currentMonthStart },
        },
      });
    const redeemedThisMonth = currentMonthRedeemed.reduce(
      (sum, txn) => sum + Number(txn.points || 0),
      0,
    );
    if (
      Number(redemptionRule.maximumPointsPerMonth || 0) > 0 &&
      redeemedThisMonth + normalizedPoints >
        Number(redemptionRule.maximumPointsPerMonth || 0)
    ) {
      throw new BadRequestException(
        'Requested points exceed the monthly redemption limit.',
      );
    }

    const ratio =
      Number(redemptionRule.cashCreditAmount) /
      Number(redemptionRule.pointsRequired);
    const creditValue = Number((normalizedPoints * ratio).toFixed(2));

    return this.prisma.$transaction(async (tx) => {
      const debit = await tx.rewardPointTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: wallet.id,
          transactionType: 'REDEEMED',
          actionCode: 'POINT_REDEMPTION',
          points: normalizedPoints,
          reason: `Redeemed ${normalizedPoints} points into SHIELD cash wallet credit`,
          createdBy: staffUserId,
          approvedBy: staffUserId,
          approvedAt: new Date(),
          status: 'APPROVED',
        },
      });

      const credit = await tx.cashWalletTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: wallet.id,
          transactionType: 'POINT_REDEMPTION_CREDIT',
          amount: creditValue,
          remarks: 'Cash wallet credit from reward redemption',
          createdBy: staffUserId,
          referenceType: 'REWARD_POINT_TRANSACTION',
          referenceId: debit.id,
        },
      });

      return {
        pointsDebited: debit,
        cashCredited: credit,
        creditValue,
      };
    });
  }

  async getTransactions(
    walletId: bigint,
    filters: { from?: string; to?: string; type?: string },
  ) {
    const dateFilter = this.buildDateFilter(filters);

    const [cashTransactions, rewardTransactions] = await Promise.all([
      this.prisma.cashWalletTransaction.findMany({
        where: {
          walletId,
          ...(filters.type
            ? { transactionType: filters.type.toUpperCase() }
            : {}),
          ...(dateFilter ? { createdAt: dateFilter } : {}),
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.rewardPointTransaction.findMany({
        where: {
          walletId,
          ...(filters.type
            ? { transactionType: filters.type.toUpperCase() }
            : {}),
          ...(dateFilter ? { createdAt: dateFilter } : {}),
        },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const splitTransactions = [
      ...cashTransactions.map((txn) => ({
        ledger: 'CASH',
        id: txn.id,
        transactionType: txn.transactionType,
        amount: Number(txn.amount || 0),
        remarks: txn.remarks,
        createdAt: txn.createdAt,
        referenceType: txn.referenceType,
        referenceId: txn.referenceId,
      })),
      ...rewardTransactions.map((txn) => ({
        ledger: 'REWARD_POINTS',
        id: txn.id,
        transactionType: txn.transactionType,
        amount: Number(txn.points || 0),
        remarks: txn.reason,
        createdAt: txn.createdAt,
        referenceType: txn.referenceType,
        referenceId: txn.referenceId,
        status: txn.status,
        actionCode: txn.actionCode,
      })),
    ].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

    if (splitTransactions.length > 0) {
      return splitTransactions;
    }

    const legacyTransactions = await this.prisma.walletTransaction.findMany({
      where: {
        walletId,
        ...(filters.type
          ? { transactionType: filters.type.toUpperCase() }
          : {}),
        ...(dateFilter ? { createdAt: dateFilter } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });

    return legacyTransactions.map((txn) => ({
      ledger: txn.subLedgerType || 'CASH',
      id: txn.id,
      transactionType: txn.transactionType || 'DEBIT',
      amount: Number(txn.amount || 0),
      remarks: txn.remarks,
      createdAt: txn.createdAt,
      referenceType: txn.referenceType,
      referenceId: txn.referenceId,
    }));
  }

  async ensureSufficientCashBalance(
    customerId: bigint,
    requiredAmount: number,
  ) {
    const wallet = await this.requireWallet(customerId);
    const summary = await this.getWalletSummary(wallet.id);
    if (summary.cashWallet.available < requiredAmount) {
      throw new BadRequestException('Insufficient cash wallet balance.');
    }
    return wallet;
  }

  async createLedgerEntry(args: {
    walletId: bigint;
    transactionType: string;
    subLedgerType: WalletLedgerType;
    amount: number;
    remarks: string;
    createdBy?: bigint;
    referenceType?: string;
    referenceId?: bigint;
    metadata?: Record<string, any>;
    actionCode?: string;
    approvedBy?: bigint;
    approvedAt?: Date;
    status?: string;
    serviceType?: string;
    expiresAt?: Date;
  }) {
    const normalizedAmount = this.assertPositiveAmount(args.amount);

    if (args.subLedgerType === WALLET_LEDGER_TYPES.REWARD_POINTS) {
      return this.prisma.rewardPointTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: args.walletId,
          transactionType: args.transactionType,
          actionCode: args.actionCode,
          points: normalizedAmount,
          reason: args.remarks,
          createdBy: args.createdBy,
          approvedBy: args.approvedBy,
          approvedAt: args.approvedAt,
          referenceType: args.referenceType,
          referenceId: args.referenceId,
          status: args.status || 'APPROVED',
          expiresAt: args.expiresAt,
          metadata: args.metadata,
        },
      });
    }

    if (args.subLedgerType === WALLET_LEDGER_TYPES.SHIELD_BENEFIT) {
      return this.prisma.benefitLedgerTransaction.create({
        data: {
          uuid: randomUUID(),
          walletId: args.walletId,
          transactionType: args.transactionType,
          amount: normalizedAmount,
          serviceType: args.serviceType,
          remarks: args.remarks,
          createdBy: args.createdBy,
          referenceType: args.referenceType,
          referenceId: args.referenceId,
          metadata: args.metadata,
        },
      });
    }

    return this.prisma.cashWalletTransaction.create({
      data: {
        uuid: randomUUID(),
        walletId: args.walletId,
        transactionType: args.transactionType,
        amount: normalizedAmount,
        remarks: args.remarks,
        createdBy: args.createdBy,
        referenceType: args.referenceType,
        referenceId: args.referenceId,
        metadata: args.metadata,
      },
    });
  }

  async getWalletSummary(walletId: bigint) {
    const [cashTransactions, rewardTransactions, benefitTransactions] =
      await Promise.all([
        this.prisma.cashWalletTransaction.findMany({ where: { walletId } }),
        this.prisma.rewardPointTransaction.findMany({ where: { walletId } }),
        this.prisma.benefitLedgerTransaction.findMany({ where: { walletId } }),
      ]);

    if (
      cashTransactions.length === 0 &&
      rewardTransactions.length === 0 &&
      benefitTransactions.length === 0
    ) {
      const legacyTransactions = await this.prisma.walletTransaction.findMany({
        where: { walletId },
      });

      let cashAvailable = 0;
      let cashCredited = 0;
      let cashDebited = 0;
      let pointsAvailable = 0;
      let pointsEarned = 0;
      let pointsRedeemed = 0;

      for (const txn of legacyTransactions) {
        const amount = Number(txn.amount || 0);
        const ledgerType = (txn.subLedgerType || 'CASH').toUpperCase();
        const transactionType = (txn.transactionType || 'DEBIT').toUpperCase();
        const isPositive = this.isPositiveCashEntry(transactionType);

        if (ledgerType === WALLET_LEDGER_TYPES.REWARD_POINTS) {
          if (isPositive) {
            pointsAvailable += amount;
            pointsEarned += amount;
          } else {
            pointsAvailable -= amount;
            pointsRedeemed += amount;
          }
          continue;
        }

        if (ledgerType === WALLET_LEDGER_TYPES.SHIELD_BENEFIT) {
          continue;
        }

        if (isPositive) {
          cashAvailable += amount;
          cashCredited += amount;
        } else {
          cashAvailable -= amount;
          cashDebited += amount;
        }
      }

      return {
        cashWallet: {
          available: Number(cashAvailable.toFixed(2)),
          credited: Number(cashCredited.toFixed(2)),
          debited: Number(cashDebited.toFixed(2)),
        },
        rewardPoints: {
          available: Number(pointsAvailable.toFixed(2)),
          earned: Number(pointsEarned.toFixed(2)),
          redeemed: Number(pointsRedeemed.toFixed(2)),
        },
        shieldBenefit: {
          remaining: 0,
          granted: 0,
          appliedTotal: 0,
        },
      };
    }

    let cashAvailable = 0;
    let cashCredited = 0;
    let cashDebited = 0;
    for (const txn of cashTransactions) {
      const amount = Number(txn.amount || 0);
      if (this.isPositiveCashEntry(txn.transactionType)) {
        cashAvailable += amount;
        cashCredited += amount;
      } else {
        cashAvailable -= amount;
        cashDebited += amount;
      }
    }

    let pointsAvailable = 0;
    let pointsEarned = 0;
    let pointsRedeemed = 0;
    for (const txn of rewardTransactions) {
      const points = Number(txn.points || 0);
      if (this.isPositiveRewardEntry(txn.transactionType)) {
        pointsAvailable += points;
        pointsEarned += points;
      } else {
        pointsAvailable -= points;
        pointsRedeemed += points;
      }
    }

    let benefitRemaining = 0;
    let benefitGranted = 0;
    let benefitAppliedTotal = 0;
    for (const txn of benefitTransactions) {
      const amount = Number(txn.amount || 0);
      if (this.isPositiveBenefitEntry(txn.transactionType)) {
        benefitRemaining += amount;
        benefitGranted += amount;
      } else {
        benefitRemaining -= amount;
        benefitAppliedTotal += amount;
      }
    }

    return {
      cashWallet: {
        available: Number(cashAvailable.toFixed(2)),
        credited: Number(cashCredited.toFixed(2)),
        debited: Number(cashDebited.toFixed(2)),
      },
      rewardPoints: {
        available: Number(pointsAvailable.toFixed(2)),
        earned: Number(pointsEarned.toFixed(2)),
        redeemed: Number(pointsRedeemed.toFixed(2)),
      },
      shieldBenefit: {
        remaining: Number(benefitRemaining.toFixed(2)),
        granted: Number(benefitGranted.toFixed(2)),
        appliedTotal: Number(benefitAppliedTotal.toFixed(2)),
      },
    };
  }

  private async requireWallet(customerId: bigint) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { customerId },
    });
    if (!wallet) {
      throw new NotFoundException(
        `Wallet not found for customer ID ${customerId}`,
      );
    }
    return wallet;
  }

  private assertPositiveAmount(amount: number) {
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new BadRequestException('Amount must be greater than zero.');
    }
    return Number(amount.toFixed(2));
  }

  private buildDateFilter(filters: { from?: string; to?: string }) {
    if (!filters.from && !filters.to) {
      return undefined;
    }

    const createdAt: Record<string, Date> = {};
    if (filters.from) {
      createdAt.gte = new Date(filters.from);
    }
    if (filters.to) {
      createdAt.lte = new Date(filters.to);
    }
    return createdAt;
  }

  private isPositiveCashEntry(transactionType: string) {
    return [
      'CREDIT',
      'RECHARGE',
      'OPENING_BALANCE',
      'POINT_REDEMPTION_CREDIT',
      'REVERSAL_CREDIT',
    ].includes(transactionType.toUpperCase());
  }

  private isPositiveRewardEntry(transactionType: string) {
    return ['EARNED', 'BONUS', 'REFERRAL_REWARDED', 'APPROVED_CREDIT'].includes(
      transactionType.toUpperCase(),
    );
  }

  private isPositiveBenefitEntry(transactionType: string) {
    return ['GRANT', 'PRELOAD', 'REVERSAL_CREDIT'].includes(
      transactionType.toUpperCase(),
    );
  }
}
