import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/wallet.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../shared/domain/customer_access_state.dart';
import '../../../../../shared/widgets/portal_support.dart';
import '../../../../customer/shared/widgets/error_card.dart';
import '../controllers/wallet_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/reward_points_card.dart';
import '../widgets/transaction_list.dart';
import '../widgets/wallet_filters.dart';
import '../widgets/wallet_shimmer.dart';

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  late final WalletController _controller;
  late Future<Customer> _customerFuture;
  String _selectedLedger = 'ALL';

  @override
  void initState() {
    super.initState();
    _controller = WalletController()..load();
    _customerFuture = ApiService.getCustomerProfile(
      ApiService.requireAuthenticatedCustomerId(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Customer>(
      future: _customerFuture,
      builder: (context, customerSnapshot) {
        if (customerSnapshot.connectionState == ConnectionState.waiting) {
          return const WalletShimmer();
        }

        if (!customerSnapshot.hasData) {
          return ErrorCard(
            title: 'Wallet unavailable',
            message: 'The customer access state could not be loaded.',
            onRetry: () {
              setState(() {
                _customerFuture = ApiService.getCustomerProfile(
                  ApiService.requireAuthenticatedCustomerId(),
                );
              });
            },
          );
        }

        final customer = customerSnapshot.data!;

        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final accessState = CustomerAccessState(
              customer: customer,
              customerStatus: customer.status,
            );
        if (_controller.isLoading && !_controller.hasData) {
          return const WalletShimmer();
        }

        if (_controller.error != null && !_controller.hasData) {
          return ErrorCard(
            title: 'Wallet unavailable',
            message: 'The local wallet preview could not be loaded.',
            onRetry: _controller.load,
          );
        }

        final wallet = _controller.wallet;
        if (wallet == null) {
          return ErrorCard(
            title: 'Wallet unavailable',
            message: 'No wallet data is available right now.',
            onRetry: _controller.load,
          );
        }

        if (!accessState.serviceAccessEnabled) {
          return _LockedWalletView(customer: customer);
        }

        final visibleTransactions = wallet.recentTransactions.where((txn) {
          return _selectedLedger == 'ALL' || txn.subLedgerType == _selectedLedger;
        }).toList();

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          color: AppColors.shieldBlue,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              _WalletHero(
                status: wallet.status,
                cashBalance: wallet.cashWallet.available,
                pointsBalance: wallet.rewardWallet.available,
                creditAvailable: wallet.statistics.creditAvailable,
                monthlySpend: wallet.statistics.monthlySpend,
                rewardCredits: wallet.statistics.rewardCredits,
              ),
              const SizedBox(height: 20),
              Text('Recent activity', style: AppTypography.h4),
              const SizedBox(height: 10),
              WalletFilters(
                selectedLedger: _selectedLedger,
                onSelected: (value) {
                  setState(() {
                    _selectedLedger = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TransactionList(
                transactions: visibleTransactions,
                ledgerBalanceAfter: (txn) => _ledgerBalanceAfter(
                  wallet.recentTransactions,
                  txn,
                ),
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  double _ledgerBalanceAfter(
    List<WalletTransaction> transactions,
    WalletTransaction target,
  ) {
    final sameLedger = transactions
        .where((txn) => txn.subLedgerType == target.subLedgerType)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    var balance = 0.0;
    for (final txn in sameLedger) {
      balance += txn.isCredit ? txn.amount : -txn.amount;
      if (txn.id == target.id) {
        return balance;
      }
    }
    return balance;
  }
}

class _LockedWalletView extends StatelessWidget {
  const _LockedWalletView({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.warning, AppColors.shieldBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Wallet pending activation',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'LOCKED',
                      style: AppTypography.tiny.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'SHIELD wallet benefits unlock only after admin or agent card issuance for ${customer.fullName}.',
                style: AppTypography.small.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _LockedWalletChip(label: 'Profile created'),
                  _LockedWalletChip(label: 'Membership pending'),
                  _LockedWalletChip(label: 'Products can stay visible'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What happens next', style: AppTypography.h4),
              const SizedBox(height: 12),
              Text(
                '1. SHIELD admin or agent team reviews the registration.\n'
                '2. Membership and digital card are issued.\n'
                '3. Wallet-linked services, benefits, and redemptions become available.',
                style: AppTypography.body.copyWith(color: AppColors.darkGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Material(
                color: AppColors.shieldBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => context.go('/portal/customer/services'),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Browse products',
                      textAlign: TextAlign.center,
                      style: AppTypography.small.copyWith(
                        color: AppColors.shieldBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: AppColors.shieldBlue,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => context.go('/portal/customer/membership'),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'View status',
                      textAlign: TextAlign.center,
                      style: AppTypography.small.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LockedWalletChip extends StatelessWidget {
  const _LockedWalletChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({
    required this.status,
    required this.cashBalance,
    required this.pointsBalance,
    required this.creditAvailable,
    required this.monthlySpend,
    required this.rewardCredits,
  });

  final String status;
  final double cashBalance;
  final double pointsBalance;
  final double creditAvailable;
  final double monthlySpend;
  final double rewardCredits;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.shieldBlue, AppColors.shieldNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Wallet overview',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cash, points, credit, and ledger movement in one compact customer view.',
            style: AppTypography.small.copyWith(
              color: AppColors.white.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroStatBlock(
                    width: itemWidth,
                    label: 'Cash',
                    value: '₹${cashBalance.toStringAsFixed(0)}',
                    secondary: '${pointsBalance.toStringAsFixed(0)} reward pts',
                  ),
                  _HeroStatBlock(
                    width: itemWidth,
                    label: 'Credit',
                    value: '₹${creditAvailable.toStringAsFixed(0)}',
                    secondary: '₹${monthlySpend.toStringAsFixed(0)} spent this cycle',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BalanceCard(
                  title: 'Cash balance',
                  value: '₹${cashBalance.toStringAsFixed(0)}',
                  caption: 'Redeemable portal cash',
                  icon: Icons.currency_rupee,
                  dark: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RewardPointsCard(
                  title: 'Points balance',
                  value: '${pointsBalance.toStringAsFixed(0)} pts',
                  caption: 'Referral + loyalty rewards',
                  icon: Icons.stars_rounded,
                  dark: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BalanceCard(
                  title: 'Monthly spend',
                  value: '₹${monthlySpend.toStringAsFixed(0)}',
                  caption: 'Pharmacy + services',
                  icon: Icons.arrow_upward_rounded,
                  dark: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RewardPointsCard(
                  title: 'Rewards earned',
                  value: '${rewardCredits.toStringAsFixed(0)} pts',
                  caption: 'Approved referrals + promos',
                  icon: Icons.card_giftcard_outlined,
                  dark: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WalletActions(),
        ],
      ),
    );
  }
}

class _HeroStatBlock extends StatelessWidget {
  const _HeroStatBlock({
    required this.label,
    required this.value,
    required this.secondary,
    this.width,
  });

  final String label;
  final String value;
  final String secondary;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.tiny.copyWith(
              color: AppColors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small.copyWith(
              color: AppColors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleWidth = constraints.maxWidth;
        final twoColumnWidth = constraints.maxWidth >= 280
            ? (constraints.maxWidth - 12) / 2
            : singleWidth;

        Widget action(String label, VoidCallback onTap, {bool full = false}) {
          return SizedBox(
            width: full ? singleWidth : twoColumnWidth,
            child: Material(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.small.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            action('Open profile', () => context.go('/portal/customer/profile')),
            action(
              'Open statement',
              () => showPortalDetailsSheet(
                context,
                title: 'Wallet statement preview',
                subtitle:
                    'Detailed statements stay grouped inside the customer wallet flow until export APIs are wired.',
                meta: 'Customer wallet',
                status: 'Live ledger',
                highlights: const [
                  'Cash and points entries remain separated by sub-ledger type.',
                  'Statement export can later connect here without changing the customer route structure.',
                ],
              ),
            ),
            action(
              'Points rules',
              () => showPortalDetailsSheet(
                context,
                title: 'Points wallet rules',
                subtitle:
                    'Referral, loyalty, and promotional points stay separate from cash.',
                meta: 'Customer wallet',
                status: 'Policy',
                highlights: const [
                  'Referral points credit only after the referred member is approved.',
                  'Wallet cash remains branch-restricted only for Hyper Pharmacy usage where applicable.',
                ],
              ),
              full: true,
            ),
          ],
        );
      },
    );
  }
}
