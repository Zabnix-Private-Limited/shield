import '../../../../../shared/models/membership.dart';
import '../../../../../shared/models/wallet.dart';

class CustomerWalletEntity {
  const CustomerWalletEntity({
    required this.walletId,
    required this.customerId,
    required this.status,
    required this.cashWallet,
    required this.rewardWallet,
    required this.benefitSummary,
    required this.recentTransactions,
    required this.statistics,
    required this.membership,
  });

  final String walletId;
  final String customerId;
  final String status;
  final CashWalletEntity cashWallet;
  final RewardWalletEntity rewardWallet;
  final BenefitSummaryEntity benefitSummary;
  final List<WalletTransaction> recentTransactions;
  final WalletStatisticsEntity statistics;
  final Membership membership;
}

class CashWalletEntity {
  const CashWalletEntity({
    required this.available,
    required this.credited,
    required this.debited,
  });

  final double available;
  final double credited;
  final double debited;
}

class RewardWalletEntity {
  const RewardWalletEntity({
    required this.available,
    required this.earned,
    required this.redeemed,
  });

  final double available;
  final double earned;
  final double redeemed;
}

class BenefitSummaryEntity {
  const BenefitSummaryEntity({
    required this.benefitsUsed,
    required this.grantedTotal,
    required this.appliedTotal,
    required this.availableBalance,
  });

  final double benefitsUsed;
  final double grantedTotal;
  final double appliedTotal;
  final double availableBalance;
}

class WalletStatisticsEntity {
  const WalletStatisticsEntity({
    required this.monthlySpend,
    required this.rewardCredits,
    required this.creditAvailable,
  });

  final double monthlySpend;
  final double rewardCredits;
  final double creditAvailable;
}
