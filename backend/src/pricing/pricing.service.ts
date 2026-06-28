import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import {
  PricingEvaluation,
  PricingEvaluationInput,
  ShieldServiceType,
} from './pricing.types';

type LedgerBalances = {
  walletId: bigint;
  cash: number;
  rewardPoints: number;
  hiddenBenefit: number;
};

type PreloadConfig = {
  cashPreloadEnabled: boolean;
  cashPreloadAmount: number;
  benefitPreloadEnabled: boolean;
  benefitPreloadAmount: number;
};

@Injectable()
export class PricingService {
  constructor(private readonly prisma: PrismaService) {}

  async getWalletLedgerBalances(customerId: bigint): Promise<LedgerBalances> {
    const wallet = await this.prisma.wallet.findUnique({
      where: { customerId },
    });
    if (!wallet) {
      throw new NotFoundException(`Wallet not found for customer ID ${customerId}`);
    }

    const [cashAgg, rewardAgg, benefitAgg] = await Promise.all([
      this.prisma.cashWalletTransaction.findMany({ where: { walletId: wallet.id } }),
      this.prisma.rewardPointTransaction.findMany({ where: { walletId: wallet.id } }),
      this.prisma.benefitLedgerTransaction.findMany({ where: { walletId: wallet.id } }),
    ]);

    const cash = cashAgg.reduce((sum, txn) => {
      const amount = Number(txn.amount || 0);
      return sum + (this.isPositiveCashEntry(txn.transactionType) ? amount : -amount);
    }, 0);

    const rewardPoints = rewardAgg.reduce((sum, txn) => {
      const points = Number(txn.points || 0);
      return sum + (this.isPositiveRewardEntry(txn.transactionType) ? points : -points);
    }, 0);

    const hiddenBenefit = benefitAgg.reduce((sum, txn) => {
      const amount = Number(txn.amount || 0);
      return sum + (this.isPositiveBenefitEntry(txn.transactionType) ? amount : -amount);
    }, 0);

    return {
      walletId: wallet.id,
      cash: Number(cash.toFixed(2)),
      rewardPoints: Number(rewardPoints.toFixed(2)),
      hiddenBenefit: Number(hiddenBenefit.toFixed(2)),
    };
  }

  async evaluateServicePrice(
    input: PricingEvaluationInput,
  ): Promise<PricingEvaluation> {
    const customer = await this.prisma.customer.findUnique({
      where: { id: input.customerId },
      include: {
        membership: {
          include: {
            membershipType: true,
          },
        },
      },
    });
    if (!customer) {
      throw new NotFoundException(`Customer with ID ${input.customerId} not found`);
    }

    const [serviceRule, balances, referralRule, preloadConfig] = await Promise.all([
      this.prisma.serviceBenefitRule.findUnique({
        where: { serviceType: input.serviceType },
      }),
      this.getWalletLedgerBalances(input.customerId),
      this.findRewardPointRule(this.getServiceActionCode(input.serviceType)),
      this.getPreloadConfig(),
    ]);

    if (!serviceRule) {
      throw new BadRequestException(`Commercial rule missing for ${input.serviceType}.`);
    }

    const originalAmount = Number(input.originalAmount.toFixed(2));
    const allowedWallets = this.parseWalletsAllowed(serviceRule.walletsAllowed);
    const benefitEligible =
      Boolean(serviceRule.isBenefitEligible) &&
      allowedWallets.includes('BENEFIT') &&
      balances.hiddenBenefit > 0;
    const benefitApplied = benefitEligible
      ? Math.min(
          Number(serviceRule.maxBenefitAmount || 0),
          balances.hiddenBenefit,
          originalAmount,
        )
      : 0;

    const afterBenefit = Number((originalAmount - benefitApplied).toFixed(2));
    const membershipDiscountRate = Number(
      customer.membership?.membershipType?.discountPercentage || 0,
    );
    const membershipDiscountApplied = Number(
      (afterBenefit * (membershipDiscountRate / 100)).toFixed(2),
    );
    const afterMembership = Math.max(
      0,
      Number((afterBenefit - membershipDiscountApplied).toFixed(2)),
    );

    const requestedRewardPoints = Number(input.requestedRewardPoints || 0);
    const activeRedemptionRule = await this.prisma.rewardRedemptionRule.findFirst({
      where: { status: 'ACTIVE' },
      orderBy: { createdAt: 'asc' },
    });

    let rewardPointsRedeemed = 0;
    let rewardPointCreditValue = 0;
    if (
      requestedRewardPoints > 0 &&
      activeRedemptionRule &&
      allowedWallets.includes('REWARD_POINTS')
    ) {
      const minimumPoints = Number(activeRedemptionRule.minimumPoints || 0);
      const redeemablePoints = Math.min(requestedRewardPoints, balances.rewardPoints);
      if (redeemablePoints >= minimumPoints) {
        const ratio =
          Number(activeRedemptionRule.cashCreditAmount) /
          Number(activeRedemptionRule.pointsRequired);
        rewardPointsRedeemed = Number(redeemablePoints.toFixed(2));
        rewardPointCreditValue = Number(
          Math.min(afterMembership, redeemablePoints * ratio).toFixed(2),
        );
      }
    }

    const finalPayableAmount = Math.max(
      0,
      Number((afterMembership - rewardPointCreditValue).toFixed(2)),
    );

    const rewardPointsEarned = Number(
      referralRule && referralRule.status === 'ACTIVE'
        ? referralRule.points
        : serviceRule.rewardPointsOnService || 0,
    );

    const customerVisibleLines = [
      ...(benefitApplied > 0
        ? [{ label: 'SHIELD Benefit Applied', amount: benefitApplied }]
        : []),
      ...(membershipDiscountApplied > 0
        ? [{ label: 'Membership Discount Applied', amount: membershipDiscountApplied }]
        : []),
      ...(rewardPointCreditValue > 0
        ? [{ label: 'Reward Credit Applied', amount: rewardPointCreditValue }]
        : []),
    ];

    if (input.persistAudit) {
      await this.prisma.pricingRuleAudit.create({
        data: {
          uuid: randomUUID(),
          walletId: balances.walletId,
          customerId: input.customerId,
          serviceType: input.serviceType,
          originalAmount,
          benefitApplied,
          membershipDiscountApplied,
          rewardPointsEarned,
          rewardPointsRedeemed,
          rewardCreditApplied: rewardPointCreditValue,
          cashWalletDeducted: finalPayableAmount,
          finalPayableAmount,
          matchedRuleCode: serviceRule.serviceType,
          preloadingUsed:
            preloadConfig.cashPreloadEnabled || preloadConfig.benefitPreloadEnabled,
          metadata: {
            referenceType: input.referenceType,
            referenceId: input.referenceId?.toString(),
            allowedWallets,
            allowExternalPayment: serviceRule.allowExternalPayment,
            customerVisibleLines,
          },
        },
      });
    }

    return {
      serviceType: input.serviceType,
      originalAmount,
      benefitEligible,
      benefitApplied: Number(benefitApplied.toFixed(2)),
      membershipDiscountApplied,
      rewardPointsEarned: Number(rewardPointsEarned.toFixed(2)),
      rewardPointsRedeemed: Number(rewardPointsRedeemed.toFixed(2)),
      rewardPointCreditValue,
      finalPayableAmount,
      cashWalletAvailable: balances.cash,
      rewardPointsAvailable: balances.rewardPoints,
      benefitAppliedToCurrentTransaction: Number(benefitApplied.toFixed(2)),
      allowedWallets,
      allowExternalPayment: Boolean(serviceRule.allowExternalPayment),
      matchedRuleCode: serviceRule.serviceType,
      preloadConfigUsed:
        preloadConfig.cashPreloadEnabled || preloadConfig.benefitPreloadEnabled,
      qualifiesReferralReward: serviceRule.qualifiesReferralReward,
      customerVisibleLines,
    };
  }

  async getAdminCommercialConfig() {
    const [serviceRules, rewardRules, redemptionRules, settings] = await Promise.all([
      this.prisma.serviceBenefitRule.findMany({ orderBy: { serviceType: 'asc' } }),
      this.prisma.rewardPointRule.findMany({ orderBy: { actionCode: 'asc' } }),
      this.prisma.rewardRedemptionRule.findMany({ orderBy: { createdAt: 'asc' } }),
      this.prisma.commercialSetting.findMany({ orderBy: { code: 'asc' } }),
    ]);

    return {
      serviceRules,
      rewardRules,
      redemptionRules,
      settings,
    };
  }

  async getPricingAudits(limit = 50) {
    return this.prisma.pricingRuleAudit.findMany({
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        customer: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            customerCode: true,
          },
        },
      },
    });
  }

  async upsertServiceRule(input: any) {
    return this.prisma.serviceBenefitRule.upsert({
      where: { serviceType: input.service_type },
      update: {
        isBenefitEligible: Boolean(input.is_benefit_eligible),
        maxBenefitAmount: Number(input.max_benefit_amount || 0),
        walletsAllowed: Array.isArray(input.wallets_allowed)
          ? input.wallets_allowed.join(',')
          : input.wallets_allowed,
        allowExternalPayment:
          input.allow_external_payment === undefined
            ? true
            : Boolean(input.allow_external_payment),
        qualifiesReferralReward:
          input.qualifies_referral_reward === undefined
            ? true
            : Boolean(input.qualifies_referral_reward),
        rewardPointsOnService: Number(input.reward_points_on_service || 0),
        status: input.status || 'ACTIVE',
      },
      create: {
        uuid: randomUUID(),
        serviceType: input.service_type,
        isBenefitEligible: Boolean(input.is_benefit_eligible),
        maxBenefitAmount: Number(input.max_benefit_amount || 0),
        walletsAllowed: Array.isArray(input.wallets_allowed)
          ? input.wallets_allowed.join(',')
          : input.wallets_allowed || 'CASH',
        allowExternalPayment:
          input.allow_external_payment === undefined
            ? true
            : Boolean(input.allow_external_payment),
        qualifiesReferralReward:
          input.qualifies_referral_reward === undefined
            ? true
            : Boolean(input.qualifies_referral_reward),
        rewardPointsOnService: Number(input.reward_points_on_service || 0),
        status: input.status || 'ACTIVE',
      },
    });
  }

  async upsertRewardRule(input: any) {
    return this.prisma.rewardPointRule.upsert({
      where: { actionCode: input.action_code },
      update: {
        displayName: input.display_name,
        points: Number(input.points || 0),
        requiresApproval: Boolean(input.requires_approval),
        status: input.status || 'ACTIVE',
        metadata: input.metadata,
      },
      create: {
        uuid: randomUUID(),
        actionCode: input.action_code,
        displayName: input.display_name,
        points: Number(input.points || 0),
        requiresApproval: Boolean(input.requires_approval),
        status: input.status || 'ACTIVE',
        metadata: input.metadata,
      },
    });
  }

  async upsertRedemptionRule(input: any) {
    return this.prisma.rewardRedemptionRule.upsert({
      where: { code: input.code },
      update: {
        pointsRequired: Number(input.points_required || 0),
        cashCreditAmount: Number(input.cash_credit_amount || 0),
        minimumPoints: Number(input.minimum_points || 0),
        maximumPointsPerMonth: Number(input.maximum_points_per_month || 0),
        expiryMonths: Number(input.expiry_months || 24),
        creditLedgerType: input.credit_ledger_type || 'CASH',
        status: input.status || 'ACTIVE',
      },
      create: {
        uuid: randomUUID(),
        code: input.code,
        pointsRequired: Number(input.points_required || 0),
        cashCreditAmount: Number(input.cash_credit_amount || 0),
        minimumPoints: Number(input.minimum_points || 0),
        maximumPointsPerMonth: Number(input.maximum_points_per_month || 0),
        expiryMonths: Number(input.expiry_months || 24),
        creditLedgerType: input.credit_ledger_type || 'CASH',
        status: input.status || 'ACTIVE',
      },
    });
  }

  async upsertCommercialSetting(input: any) {
    return this.prisma.commercialSetting.upsert({
      where: { code: input.code },
      update: {
        valueType: input.value_type,
        valueText: input.value_text ?? null,
        valueNumber:
          input.value_number === undefined ? null : Number(input.value_number),
        valueBoolean:
          input.value_boolean === undefined ? null : Boolean(input.value_boolean),
        status: input.status || 'ACTIVE',
      },
      create: {
        uuid: randomUUID(),
        code: input.code,
        valueType: input.value_type,
        valueText: input.value_text ?? null,
        valueNumber:
          input.value_number === undefined ? null : Number(input.value_number),
        valueBoolean:
          input.value_boolean === undefined ? null : Boolean(input.value_boolean),
        status: input.status || 'ACTIVE',
      },
    });
  }

  async getPreloadConfig(): Promise<PreloadConfig> {
    const settings = await this.prisma.commercialSetting.findMany({
      where: {
        code: {
          in: [
            'CASH_WALLET_PRELOAD_ENABLED',
            'DEFAULT_CASH_WALLET_PRELOAD_AMOUNT',
            'BENEFIT_PRELOAD_ENABLED',
            'DEFAULT_BENEFIT_PRELOAD_AMOUNT',
          ],
        },
      },
    });

    const byCode = new Map(settings.map((setting) => [setting.code, setting]));
    return {
      cashPreloadEnabled:
        byCode.get('CASH_WALLET_PRELOAD_ENABLED')?.valueBoolean ?? false,
      cashPreloadAmount: Number(
        byCode.get('DEFAULT_CASH_WALLET_PRELOAD_AMOUNT')?.valueNumber || 0,
      ),
      benefitPreloadEnabled:
        byCode.get('BENEFIT_PRELOAD_ENABLED')?.valueBoolean ?? false,
      benefitPreloadAmount: Number(
        byCode.get('DEFAULT_BENEFIT_PRELOAD_AMOUNT')?.valueNumber || 0,
      ),
    };
  }

  async findRewardPointRule(actionCode: string) {
    return this.prisma.rewardPointRule.findUnique({
      where: { actionCode },
    });
  }

  getServiceActionCode(serviceType: ShieldServiceType) {
    const map: Record<ShieldServiceType, string> = {
      PHARMACY: 'PHARMACY_PURCHASE',
      LAB: 'LAB_TEST',
      DOCTOR: 'DOCTOR_CONSULTATION',
      DENTAL: 'DENTAL_CONSULTATION',
      COSMETIC: 'COSMETIC_CONSULTATION',
      DIETITIAN: 'DIETITIAN_CONSULTATION',
      HOMECARE: 'HOMECARE_VISIT',
    };
    return map[serviceType];
  }

  private parseWalletsAllowed(value?: string | null) {
    return (value || 'CASH')
      .split(',')
      .map((item) => item.trim().toUpperCase())
      .filter(Boolean);
  }

  private isPositiveCashEntry(transactionType: string) {
    return ['CREDIT', 'RECHARGE', 'OPENING_BALANCE', 'POINT_REDEMPTION_CREDIT', 'REVERSAL_CREDIT']
      .includes(transactionType.toUpperCase());
  }

  private isPositiveRewardEntry(transactionType: string) {
    return ['EARNED', 'BONUS', 'REFERRAL_REWARDED', 'APPROVED_CREDIT'].includes(
      transactionType.toUpperCase(),
    );
  }

  private isPositiveBenefitEntry(transactionType: string) {
    return ['GRANT', 'PRELOAD', 'REVERSAL_CREDIT'].includes(transactionType.toUpperCase());
  }
}
