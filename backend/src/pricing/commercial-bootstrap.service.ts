import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { SERVICE_TYPES } from './pricing.types';

@Injectable()
export class CommercialBootstrapService implements OnModuleInit {
  private readonly logger = new Logger(CommercialBootstrapService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    await this.ensureSchemaSupport();
    await this.seedCommercialDefaults();
  }

  private async ensureSchemaSupport() {
    const ddl = [
      `CREATE TABLE IF NOT EXISTS cash_wallet_transactions (
        id BIGSERIAL PRIMARY KEY,
        uuid UUID NOT NULL UNIQUE,
        wallet_id BIGINT NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
        transaction_type VARCHAR(50) NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
        reference_type VARCHAR(100),
        reference_id BIGINT,
        remarks TEXT,
        created_by BIGINT REFERENCES users(id),
        created_at TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
        metadata JSONB
      )`,
      `CREATE INDEX IF NOT EXISTS idx_cash_wallet_transactions_wallet ON cash_wallet_transactions(wallet_id)`,
      `CREATE INDEX IF NOT EXISTS idx_cash_wallet_transactions_type ON cash_wallet_transactions(transaction_type)`,
      `CREATE INDEX IF NOT EXISTS idx_cash_wallet_transactions_date ON cash_wallet_transactions(created_at)`,
      `CREATE TABLE IF NOT EXISTS reward_point_transactions (
        id BIGSERIAL PRIMARY KEY,
        uuid UUID NOT NULL UNIQUE,
        wallet_id BIGINT NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
        transaction_type VARCHAR(50) NOT NULL,
        action_code VARCHAR(100),
        points DECIMAL(15,2) NOT NULL,
        reason TEXT,
        reference_type VARCHAR(100),
        reference_id BIGINT,
        status VARCHAR(30) NOT NULL DEFAULT 'APPROVED',
        created_by BIGINT REFERENCES users(id),
        approved_by BIGINT REFERENCES users(id),
        approved_at TIMESTAMPTZ(6),
        expires_at TIMESTAMPTZ(6),
        created_at TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
        metadata JSONB
      )`,
      `CREATE INDEX IF NOT EXISTS idx_reward_point_transactions_wallet ON reward_point_transactions(wallet_id)`,
      `CREATE INDEX IF NOT EXISTS idx_reward_point_transactions_action ON reward_point_transactions(action_code)`,
      `CREATE INDEX IF NOT EXISTS idx_reward_point_transactions_status ON reward_point_transactions(status)`,
      `CREATE INDEX IF NOT EXISTS idx_reward_point_transactions_date ON reward_point_transactions(created_at)`,
      `CREATE TABLE IF NOT EXISTS benefit_ledger_transactions (
        id BIGSERIAL PRIMARY KEY,
        uuid UUID NOT NULL UNIQUE,
        wallet_id BIGINT NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
        transaction_type VARCHAR(50) NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
        service_type VARCHAR(50),
        reference_type VARCHAR(100),
        reference_id BIGINT,
        remarks TEXT,
        created_by BIGINT REFERENCES users(id),
        created_at TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
        metadata JSONB
      )`,
      `CREATE INDEX IF NOT EXISTS idx_benefit_ledger_transactions_wallet ON benefit_ledger_transactions(wallet_id)`,
      `CREATE INDEX IF NOT EXISTS idx_benefit_ledger_transactions_service ON benefit_ledger_transactions(service_type)`,
      `CREATE INDEX IF NOT EXISTS idx_benefit_ledger_transactions_date ON benefit_ledger_transactions(created_at)`,
      `ALTER TABLE referral_reward_events ADD COLUMN IF NOT EXISTS expired_at TIMESTAMPTZ(6)`,
      `ALTER TABLE service_benefit_rules ADD COLUMN IF NOT EXISTS wallets_allowed VARCHAR(120) DEFAULT 'CASH'`,
      `ALTER TABLE service_benefit_rules ADD COLUMN IF NOT EXISTS allow_external_payment BOOLEAN NOT NULL DEFAULT TRUE`,
      `CREATE TABLE IF NOT EXISTS reward_point_rules (
        id BIGSERIAL PRIMARY KEY,
        uuid UUID NOT NULL UNIQUE,
        action_code VARCHAR(100) NOT NULL UNIQUE,
        display_name VARCHAR(255) NOT NULL,
        points DECIMAL(12,2) NOT NULL,
        requires_approval BOOLEAN NOT NULL DEFAULT FALSE,
        status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
        metadata JSONB,
        created_at TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT NOW()
      )`,
      `CREATE TABLE IF NOT EXISTS commercial_settings (
        id BIGSERIAL PRIMARY KEY,
        uuid UUID NOT NULL UNIQUE,
        code VARCHAR(100) NOT NULL UNIQUE,
        value_type VARCHAR(30) NOT NULL,
        value_text TEXT,
        value_number DECIMAL(15,2),
        value_boolean BOOLEAN,
        status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
        created_at TIMESTAMPTZ(6) NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ(6) NOT NULL DEFAULT NOW()
      )`,
      `CREATE TABLE IF NOT EXISTS pricing_rule_audits (
        id BIGSERIAL PRIMARY KEY,
        uuid UUID NOT NULL UNIQUE,
        wallet_id BIGINT REFERENCES wallets(id),
        customer_id BIGINT REFERENCES customers(id),
        service_type VARCHAR(50) NOT NULL,
        original_amount DECIMAL(15,2) NOT NULL,
        benefit_applied DECIMAL(15,2) NOT NULL DEFAULT 0,
        membership_discount_applied DECIMAL(15,2) NOT NULL DEFAULT 0,
        reward_points_earned DECIMAL(15,2) NOT NULL DEFAULT 0,
        reward_points_redeemed DECIMAL(15,2) NOT NULL DEFAULT 0,
        reward_credit_applied DECIMAL(15,2) NOT NULL DEFAULT 0,
        cash_wallet_deducted DECIMAL(15,2) NOT NULL DEFAULT 0,
        final_payable_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
        matched_rule_code VARCHAR(100),
        preloading_used BOOLEAN NOT NULL DEFAULT FALSE,
        metadata JSONB,
        created_at TIMESTAMPTZ(6) NOT NULL DEFAULT NOW()
      )`,
      `CREATE INDEX IF NOT EXISTS idx_pricing_rule_audits_wallet ON pricing_rule_audits(wallet_id)`,
      `CREATE INDEX IF NOT EXISTS idx_pricing_rule_audits_customer ON pricing_rule_audits(customer_id)`,
      `CREATE INDEX IF NOT EXISTS idx_pricing_rule_audits_service ON pricing_rule_audits(service_type)`,
      `CREATE INDEX IF NOT EXISTS idx_pricing_rule_audits_date ON pricing_rule_audits(created_at)`,
    ];

    for (const statement of ddl) {
      await this.prisma.$executeRawUnsafe(statement);
    }
  }

  private async seedCommercialDefaults() {
    const serviceDefaults: Record<string, { benefitEligible: boolean; maxBenefit: number; walletsAllowed: string; rewardPoints: number }> = {
      PHARMACY: { benefitEligible: false, maxBenefit: 0, walletsAllowed: 'CASH', rewardPoints: 0 },
      LAB: { benefitEligible: true, maxBenefit: 300, walletsAllowed: 'CASH,BENEFIT', rewardPoints: 15 },
      DOCTOR: { benefitEligible: true, maxBenefit: 500, walletsAllowed: 'CASH,BENEFIT', rewardPoints: 20 },
      DENTAL: { benefitEligible: true, maxBenefit: 500, walletsAllowed: 'CASH,BENEFIT', rewardPoints: 20 },
      COSMETIC: { benefitEligible: true, maxBenefit: 1000, walletsAllowed: 'CASH,BENEFIT', rewardPoints: 20 },
      DIETITIAN: { benefitEligible: true, maxBenefit: 500, walletsAllowed: 'CASH,BENEFIT', rewardPoints: 15 },
      HOMECARE: { benefitEligible: true, maxBenefit: 1000, walletsAllowed: 'CASH,BENEFIT', rewardPoints: 20 },
    };

    for (const serviceType of SERVICE_TYPES) {
      const defaults = serviceDefaults[serviceType];
      await this.prisma.serviceBenefitRule.upsert({
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
      await this.prisma.rewardPointRule.upsert({
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

    await this.prisma.rewardRedemptionRule.upsert({
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

    for (const [code, valueType, valueText, valueNumber, valueBoolean] of settings) {
      await this.prisma.commercialSetting.upsert({
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

    this.logger.log(
      'Commercial defaults ensured for split ledgers, pricing audit, reward rules, and preload settings.',
    );
  }
}
