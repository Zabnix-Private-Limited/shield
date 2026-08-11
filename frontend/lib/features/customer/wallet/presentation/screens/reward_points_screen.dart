import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../customer/shared/widgets/error_card.dart';
import '../controllers/wallet_controller.dart';
import '../widgets/transaction_list.dart';
import '../widgets/wallet_shimmer.dart';

class CustomerRewardPointsScreen extends StatefulWidget {
  const CustomerRewardPointsScreen({super.key});

  @override
  State<CustomerRewardPointsScreen> createState() =>
      _CustomerRewardPointsScreenState();
}

class _CustomerRewardPointsScreenState
    extends State<CustomerRewardPointsScreen> {
  late final WalletController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WalletController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      if (_controller.isLoading && !_controller.hasData) {
        return const WalletShimmer();
      }
      if (_controller.error != null && !_controller.hasData) {
        return ErrorCard(
          title: 'Reward points unavailable',
          message: 'Your reward-point ledger could not be loaded.',
          onRetry: _controller.load,
        );
      }
      final wallet = _controller.wallet;
      if (wallet == null) {
        return ErrorCard(
          title: 'Reward points unavailable',
          message: 'No reward-point ledger is available right now.',
          onRetry: _controller.load,
        );
      }
      final transactions = wallet.recentTransactions
          // The production wallet bundle identifies its dedicated reward
          // ledger as REWARD_POINTS. POINTS is retained only for legacy
          // cached transactions created before the ledger split.
          .where(
            (entry) =>
                entry.subLedgerType.toUpperCase() == 'REWARD_POINTS' ||
                entry.subLedgerType.toUpperCase() == 'POINTS',
          )
          .toList();
      return RefreshIndicator(
        onRefresh: _controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF4D68D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Reward Points', style: AppTypography.small),
                  const SizedBox(height: 8),
                  Text(
                    wallet.rewardWallet.available.toStringAsFixed(0),
                    style: AppTypography.h1.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Points are calculated from your SHIELD reward ledger. Redemption options appear only when a configured rule is available.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Points activity', style: AppTypography.h4),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              Text(
                'No reward-point activity yet.',
                style: AppTypography.body.copyWith(color: AppColors.gray),
              )
            else
              TransactionList(transactions: transactions),
          ],
        ),
      );
    },
  );
}
