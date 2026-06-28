export const WALLET_LEDGER_TYPES = {
  CASH: 'CASH',
  REWARD_POINTS: 'REWARD_POINTS',
  SHIELD_BENEFIT: 'SHIELD_BENEFIT',
} as const;

export type WalletLedgerType =
  (typeof WALLET_LEDGER_TYPES)[keyof typeof WALLET_LEDGER_TYPES];

export const SERVICE_TYPES = [
  'PHARMACY',
  'LAB',
  'DOCTOR',
  'DENTAL',
  'COSMETIC',
  'DIETITIAN',
  'HOMECARE',
] as const;

export type ShieldServiceType = (typeof SERVICE_TYPES)[number];

export type PricingEvaluationInput = {
  customerId: bigint;
  serviceType: ShieldServiceType;
  originalAmount: number;
  requestedRewardPoints?: number;
  persistAudit?: boolean;
  referenceType?: string;
  referenceId?: bigint;
};

export type PricingEvaluation = {
  serviceType: ShieldServiceType;
  originalAmount: number;
  benefitEligible: boolean;
  benefitApplied: number;
  membershipDiscountApplied: number;
  rewardPointsEarned: number;
  rewardPointsRedeemed: number;
  rewardPointCreditValue: number;
  finalPayableAmount: number;
  cashWalletAvailable: number;
  rewardPointsAvailable: number;
  benefitAppliedToCurrentTransaction: number;
  allowedWallets: string[];
  allowExternalPayment: boolean;
  matchedRuleCode: string | null;
  preloadConfigUsed: boolean;
  qualifiesReferralReward: boolean;
  customerVisibleLines: Array<{
    label: string;
    amount: number;
  }>;
};
