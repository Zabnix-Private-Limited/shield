import { Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from '../wallet/wallet.service';
import { PricingService } from '../pricing/pricing.service';

@Injectable()
export class ReferralService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly walletService: WalletService,
    private readonly pricingService: PricingService,
  ) {}

  async createPendingReferralEvent(args: {
    referrerCustomerId: bigint;
    referredCustomerId: bigint;
    referralCode?: string;
  }) {
    const rewardRule = await this.pricingService.findRewardPointRule(
      'SUCCESSFUL_REFERRAL',
    );

    return this.prisma.referralRewardEvent.upsert({
      where: { referredCustomerId: args.referredCustomerId },
      update: {
        referrerCustomerId: args.referrerCustomerId,
        referralCode: args.referralCode,
        status: 'PENDING',
        rewardPoints: Number(rewardRule?.points || 0),
      },
      create: {
        uuid: randomUUID(),
        referrerCustomerId: args.referrerCustomerId,
        referredCustomerId: args.referredCustomerId,
        referralCode: args.referralCode,
        status: 'PENDING',
        rewardPoints: Number(rewardRule?.points || 0),
      },
    });
  }

  async markReferralVerified(referredCustomerId: bigint) {
    const event = await this.prisma.referralRewardEvent.findUnique({
      where: { referredCustomerId },
    });
    if (!event || ['REJECTED', 'REWARDED', 'EXPIRED'].includes(event.status)) {
      return event;
    }

    return this.prisma.referralRewardEvent.update({
      where: { id: event.id },
      data: {
        status: 'VERIFIED',
        verifiedAt: new Date(),
      },
    });
  }

  async qualifyRewardFromTransaction(args: {
    customerId: bigint;
    serviceType: string;
    referenceType: string;
    referenceId: bigint;
    performedBy?: bigint;
  }) {
    const event = await this.prisma.referralRewardEvent.findUnique({
      where: { referredCustomerId: args.customerId },
    });
    if (!event || event.status !== 'VERIFIED') {
      return null;
    }

    const rule = await this.prisma.serviceBenefitRule.findUnique({
      where: { serviceType: args.serviceType },
    });
    if (rule && !rule.qualifiesReferralReward) {
      return null;
    }

    const qualified = await this.prisma.referralRewardEvent.update({
      where: { id: event.id },
      data: {
        status: 'QUALIFIED',
        qualifyingReferenceType: args.referenceType,
        qualifyingReferenceId: args.referenceId,
        qualifiedAt: new Date(),
        notes: `Qualified by first eligible ${args.serviceType} transaction.`,
      },
    });

    return this.rewardQualifiedReferral(qualified.id, args.performedBy);
  }

  async rejectReferral(args: {
    referredCustomerId: bigint;
    reason: string;
  }) {
    const event = await this.prisma.referralRewardEvent.findUnique({
      where: { referredCustomerId: args.referredCustomerId },
    });
    if (!event) {
      return null;
    }

    return this.prisma.referralRewardEvent.update({
      where: { id: event.id },
      data: {
        status: 'REJECTED',
        rejectedAt: new Date(),
        rejectedReason: args.reason,
      },
    });
  }

  async getReferralTree(customerId: bigint) {
    const root = await this.prisma.customer.findUnique({
      where: { id: customerId },
    });
    if (!root) {
      throw new NotFoundException(`Customer with ID ${customerId} not found`);
    }

    return this.buildTree(customerId);
  }

  async getReferralSummary(customerId: bigint) {
    const customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
    });
    if (!customer) {
      throw new NotFoundException(`Customer with ID ${customerId} not found`);
    }

    const [events, balances, children] = await Promise.all([
      this.prisma.referralRewardEvent.findMany({
        where: {
          OR: [
            { referrerCustomerId: customerId },
            { referredCustomerId: customerId },
          ],
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.walletService.getWalletByCustomerId(customerId, {
        includeHiddenBenefit: false,
      }),
      this.prisma.customer.count({
        where: { referredById: customerId },
      }),
    ]);

    const byStatus = events.reduce<Record<string, number>>((acc, event) => {
      acc[event.status] = (acc[event.status] || 0) + 1;
      return acc;
    }, {});

    return {
      customerId: customer.id,
      referralCode: customer.referralCode,
      directReferrals: children,
      totalReferrals: events.filter((event) => event.referrerCustomerId === customerId)
        .length,
      availablePoints: balances.rewardPoints.available,
      redeemedPoints: balances.rewardPoints.redeemed,
      earnedPoints: balances.rewardPoints.earned,
      statuses: byStatus,
      history: events.map((event) => ({
        referredCustomerId: event.referredCustomerId,
        status: event.status,
        rewardPoints: Number(event.rewardPoints || 0),
        createdAt: event.createdAt,
        qualifiedAt: event.qualifiedAt,
        rewardedAt: event.rewardedAt,
      })),
    };
  }

  async getCustomerReferralSummary(customerId: bigint) {
    const customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
      select: { referralCode: true },
    });
    if (!customer) throw new NotFoundException('Customer not found.');
    const events = await this.prisma.referralRewardEvent.findMany({
      where: { referrerCustomerId: customerId },
      select: {
        status: true,
        rewardPoints: true,
        createdAt: true,
        qualifiedAt: true,
        rewardedAt: true,
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    });
    const statuses = events.reduce<Record<string, number>>((result, event) => {
      result[event.status] = (result[event.status] ?? 0) + 1;
      return result;
    }, {});
    return {
      referralCode: customer.referralCode ?? null,
      directReferrals: events.length,
      totalReferrals: events.length,
      statuses,
      history: events.map((event) => ({
        status: event.status,
        rewardPoints: Number(event.rewardPoints),
        createdAt: event.createdAt,
        qualifiedAt: event.qualifiedAt,
        rewardedAt: event.rewardedAt,
      })),
    };
  }

  private async rewardQualifiedReferral(eventId: bigint, performedBy?: bigint) {
    const event = await this.prisma.referralRewardEvent.findUnique({
      where: { id: eventId },
    });
    if (!event || event.status !== 'QUALIFIED') {
      return event;
    }

    const rewardRule = await this.pricingService.findRewardPointRule(
      'SUCCESSFUL_REFERRAL',
    );
    const rewardPoints = Number(rewardRule?.points || event.rewardPoints || 0);

    const referrerWallet = await this.prisma.wallet.findUnique({
      where: { customerId: event.referrerCustomerId },
    });

    return this.prisma.$transaction(async (tx) => {
      const rewarded = await tx.referralRewardEvent.update({
        where: { id: event.id },
        data: {
          status: 'REWARDED',
          rewardPoints,
          rewardedAt: new Date(),
        },
      });

      if (referrerWallet) {
        await tx.rewardPointTransaction.create({
          data: {
            uuid: randomUUID(),
            walletId: referrerWallet.id,
            transactionType: 'REFERRAL_REWARDED',
            actionCode: 'SUCCESSFUL_REFERRAL',
            points: rewardPoints,
            reason: `Referral reward approved for customer ${event.referredCustomerId}`,
            createdBy: performedBy,
            approvedBy: performedBy,
            approvedAt: new Date(),
            status: 'APPROVED',
            referenceType: 'REFERRAL_REWARD_EVENT',
            referenceId: event.id,
            metadata: {
              rewardStatus: 'REWARDED',
            },
          },
        });
      }

      return rewarded;
    });
  }

  private async buildTree(customerId: bigint): Promise<any> {
    const customer = await this.prisma.customer.findUnique({
      where: { id: customerId },
      select: {
        id: true,
        uuid: true,
        firstName: true,
        lastName: true,
        createdAt: true,
        status: true,
      },
    });
    if (!customer) {
      return null;
    }

    const walletSummary = await this.walletService
      .getWalletByCustomerId(customerId, {
        includeHiddenBenefit: false,
      })
      .catch(() => null);

    const children = await this.prisma.customer.findMany({
      where: { referredById: customerId },
      select: { id: true },
      orderBy: { createdAt: 'asc' },
    });

    return {
      customerId: customer.id.toString(),
      name: [customer.firstName, customer.lastName].filter(Boolean).join(' ').trim(),
      registrationDate: customer.createdAt,
      active: customer.status === 'ACTIVE',
      cashWallet: walletSummary?.cashWallet.available ?? 0,
      rewardPoints: walletSummary?.rewardPoints.available ?? 0,
      children: await Promise.all(children.map((child) => this.buildTree(child.id))),
    };
  }
}
