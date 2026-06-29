import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';
import { SERVICE_TYPES } from './pricing.types';

export async function seedCommercialDefaults(prisma: PrismaClient) {
  const serviceDefaults: Record<
    string,
    {
      benefitEligible: boolean;
      maxBenefit: number;
      walletsAllowed: string;
      rewardPoints: number;
    }
  > = {
    PHARMACY: {
      benefitEligible: false,
      maxBenefit: 0,
      walletsAllowed: 'CASH',
      rewardPoints: 0,
    },
    LAB: {
      benefitEligible: true,
      maxBenefit: 300,
      walletsAllowed: 'CASH,BENEFIT',
      rewardPoints: 15,
    },
    DOCTOR: {
      benefitEligible: true,
      maxBenefit: 500,
      walletsAllowed: 'CASH,BENEFIT',
      rewardPoints: 20,
    },
    DENTAL: {
      benefitEligible: true,
      maxBenefit: 500,
      walletsAllowed: 'CASH,BENEFIT',
      rewardPoints: 20,
    },
    COSMETIC: {
      benefitEligible: true,
      maxBenefit: 1000,
      walletsAllowed: 'CASH,BENEFIT',
      rewardPoints: 20,
    },
    DIETITIAN: {
      benefitEligible: true,
      maxBenefit: 500,
      walletsAllowed: 'CASH,BENEFIT',
      rewardPoints: 15,
    },
    HOMECARE: {
      benefitEligible: true,
      maxBenefit: 1000,
      walletsAllowed: 'CASH,BENEFIT',
      rewardPoints: 20,
    },
  };

  for (const serviceType of SERVICE_TYPES) {
    const defaults = serviceDefaults[serviceType];
    await prisma.serviceBenefitRule.upsert({
      where: { serviceType },
      update: {},
      create: {
        uuid: randomUUID(),
        serviceType,
        isBenefitEligible: defaults.benefitEligible,
        maxBenefitAmount: defaults.maxBenefit,
        walletsAllowed: defaults.walletsAllowed,
        allowExternalPayment: true,
        qualifiesReferralReward: true,
        rewardPointsOnService: defaults.rewardPoints,
        status: 'ACTIVE',
      },
    });
  }

  const rewardRules = [
    ['SUCCESSFUL_REFERRAL', 'Successful Referral', 100],
    ['DOCTOR_CONSULTATION', 'Doctor Consultation', 20],
    ['LAB_TEST', 'Lab Test', 15],
    ['HEALTH_CAMP', 'Health Camp', 30],
    ['WELLNESS_EVENT', 'Wellness Event', 50],
    ['BIRTHDAY_BONUS', 'Birthday Bonus', 25],
    ['ANNIVERSARY_BONUS', 'Anniversary Bonus', 25],
    ['HOMECARE_VISIT', 'Homecare Visit', 20],
    ['DENTAL_CONSULTATION', 'Dental Consultation', 20],
    ['COSMETIC_CONSULTATION', 'Cosmetic Consultation', 20],
    ['DIETITIAN_CONSULTATION', 'Dietitian Consultation', 15],
    ['PHARMACY_PURCHASE', 'Pharmacy Purchase', 0],
  ] as const;

  for (const [actionCode, displayName, points] of rewardRules) {
    await prisma.rewardPointRule.upsert({
      where: { actionCode },
      update: {},
      create: {
        uuid: randomUUID(),
        actionCode,
        displayName,
        points,
        requiresApproval: false,
        status: 'ACTIVE',
      },
    });
  }

  await prisma.rewardRedemptionRule.upsert({
    where: { code: 'DEFAULT_POINTS_TO_CASH' },
    update: {},
    create: {
      uuid: randomUUID(),
      code: 'DEFAULT_POINTS_TO_CASH',
      pointsRequired: 1000,
      cashCreditAmount: 100,
      minimumPoints: 1000,
      maximumPointsPerMonth: 10000,
      expiryMonths: 24,
      creditLedgerType: 'CASH',
      status: 'ACTIVE',
    },
  });

  const settings = [
    ['CASH_WALLET_PRELOAD_ENABLED', 'BOOLEAN', null, null, false],
    ['DEFAULT_CASH_WALLET_PRELOAD_AMOUNT', 'NUMBER', null, 0, null],
    ['BENEFIT_PRELOAD_ENABLED', 'BOOLEAN', null, null, false],
    ['DEFAULT_BENEFIT_PRELOAD_AMOUNT', 'NUMBER', null, 0, null],
  ] as const;

  for (const [
    code,
    valueType,
    valueText,
    valueNumber,
    valueBoolean,
  ] of settings) {
    await prisma.commercialSetting.upsert({
      where: { code },
      update: {},
      create: {
        uuid: randomUUID(),
        code,
        valueType,
        valueText,
        valueNumber,
        valueBoolean,
        status: 'ACTIVE',
      },
    });
  }
}
