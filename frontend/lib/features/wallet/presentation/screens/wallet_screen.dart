import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/wallet.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/portal_support.dart';
import '../../../../shared/services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Map<String, dynamic>> _walletProfileFuture;
  late Future<List<WalletTransaction>> _transactionsFuture;
  String _selectedFilter = 'ALL';
  String _selectedType = 'ALL';
  String _providerQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  void _loadWalletData() {
    setState(() {
      _walletProfileFuture = ApiService.getWalletProfile(
        ApiService.requireAuthenticatedCustomerId(),
      );
      _transactionsFuture = _walletProfileFuture.then((profile) {
        final walletId = profile['walletId'].toString();
        return ApiService.getWalletTransactions(walletId);
      });
    });
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.shieldBlue : AppColors.lightGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.small.copyWith(
            color: isSelected ? AppColors.white : AppColors.darkGray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_walletProfileFuture, _transactionsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppCustomerSectionSkeleton(
              showHero: true,
              showActionRow: true,
              statCards: 4,
              listItems: 5,
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text('Failed to load wallet', style: AppTypography.h3),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 16),
                    AppButton(text: 'Retry', onPressed: _loadWalletData),
                  ],
                ),
              ),
            );
          }

          final txns = snapshot.data![1] as List<WalletTransaction>;

          double cashBalance = 0.0;
          double pointsBalance = 0.0;
          double totalCredits = 0.0;
          double totalDebits = 0.0;

          for (final txn in txns) {
            if (txn.subLedgerType == 'CASH') {
              if (txn.transactionType == 'CREDIT') {
                cashBalance += txn.amount;
                totalCredits += txn.amount;
              } else {
                cashBalance -= txn.amount;
                totalDebits += txn.amount;
              }
            } else if (txn.subLedgerType == 'POINTS') {
              if (txn.transactionType == 'CREDIT') {
                pointsBalance += txn.amount;
                totalCredits += txn.amount;
              } else {
                pointsBalance -= txn.amount;
                totalDebits += txn.amount;
              }
            }
          }

          final filteredTxns = txns.where((txn) {
            final matchesLedger =
                _selectedFilter == 'ALL' ||
                txn.subLedgerType == _selectedFilter;
            final matchesType =
                _selectedType == 'ALL' || txn.transactionType == _selectedType;
            final matchesProvider =
                _providerQuery.trim().isEmpty ||
                (txn.remarks ?? '').toLowerCase().contains(
                  _providerQuery.trim().toLowerCase(),
                );
            return matchesLedger && matchesType && matchesProvider;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => _loadWalletData(),
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              child: AppPageFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SHIELD Wallet Account',
                                style: AppTypography.h4.copyWith(
                                  color: AppColors.shieldNavy,
                                ),
                              ),
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: AppColors.shieldBlue,
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CASH LEDGER',
                                      style: AppTypography.tiny.copyWith(
                                        color: AppColors.gray,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${cashBalance.toStringAsFixed(2)}',
                                      style: AppTypography.h2.copyWith(
                                        color: AppColors.shieldNavy,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Recharged funds',
                                      style: AppTypography.tiny.copyWith(
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 60,
                                width: 1,
                                color: AppColors.divider,
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'POINTS LEDGER',
                                      style: AppTypography.tiny.copyWith(
                                        color: AppColors.gray,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pointsBalance.toStringAsFixed(0)} PTS',
                                      style: AppTypography.h2.copyWith(
                                        color: AppColors.shieldBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Promotional rewards',
                                      style: AppTypography.tiny.copyWith(
                                        color: AppColors.gray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Recharge Wallet',
                                  onPressed: () {
                                    context.go('/portal/customer/recharge');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Credits',
                            amount: '₹${totalCredits.toStringAsFixed(2)}',
                            color: AppColors.shieldGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Total Debits',
                            amount: '₹${totalDebits.toStringAsFixed(2)}',
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transaction History', style: AppTypography.h4),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildFilterChip('ALL', 'All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('CASH', 'Cash'),
                            const SizedBox(width: 8),
                            _buildFilterChip('POINTS', 'Points'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildTypeChip('ALL', 'All Types'),
                            const SizedBox(width: 8),
                            _buildTypeChip('CREDIT', 'Credits'),
                            const SizedBox(width: 8),
                            _buildTypeChip('DEBIT', 'Debits'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (value) =>
                              setState(() => _providerQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Filter by service provider or remarks',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: AppColors.lightGray,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...(() {
                      final chronologicalTxns = filteredTxns.reversed.toList();
                      final Map<String, double> postBalances = {};
                      final Map<String, double> ledgerBalances = {};

                      for (final txn in chronologicalTxns) {
                        final currentBalance =
                            ledgerBalances[txn.subLedgerType] ?? 0.0;
                        final nextBalance =
                            currentBalance +
                            (txn.transactionType == 'CREDIT'
                                ? txn.amount
                                : -txn.amount);
                        ledgerBalances[txn.subLedgerType] = nextBalance;
                        postBalances[txn.id] = nextBalance;
                      }

                      return filteredTxns.map((txn) {
                        final postBalance = postBalances[txn.id] ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            padding: const EdgeInsets.all(16),
                            onTap: () {
                              showPortalDetailsSheet(
                                context,
                                title: txn.remarks ?? 'Wallet transaction',
                                subtitle:
                                    'A ${txn.transactionType.toLowerCase()} entry of ₹${txn.amount.toStringAsFixed(2)} was recorded in the ${txn.subLedgerType} ledger.',
                                meta:
                                    '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year}',
                                status: txn.transactionType,
                                highlights: [
                                  'Running balance in ${txn.subLedgerType} sub-ledger after this transaction is ₹${postBalance.toStringAsFixed(2)}.',
                                  'This entry stays visible to support the ledger-based wallet model from the docs.',
                                ],
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: txn.transactionType == 'CREDIT'
                                        ? AppColors.shieldGreen.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.error.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    txn.transactionType == 'CREDIT'
                                        ? Icons.add
                                        : Icons.remove,
                                    color: txn.transactionType == 'CREDIT'
                                        ? AppColors.shieldGreen
                                        : AppColors.error,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        txn.remarks ?? 'Transaction',
                                        style: AppTypography.body.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year} • ${txn.createdAt.hour}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
                                            style: AppTypography.tiny.copyWith(
                                              color: AppColors.gray,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: txn.subLedgerType == 'CASH'
                                                  ? AppColors.shieldNavy
                                                        .withValues(alpha: 0.08)
                                                  : AppColors.shieldBlue
                                                        .withValues(
                                                          alpha: 0.08,
                                                        ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              txn.subLedgerType,
                                              style: AppTypography.tiny
                                                  .copyWith(
                                                    color:
                                                        txn.subLedgerType ==
                                                            'CASH'
                                                        ? AppColors.shieldNavy
                                                        : AppColors.shieldBlue,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${txn.transactionType == 'CREDIT' ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                                  style: AppTypography.h4.copyWith(
                                    color: txn.transactionType == 'CREDIT'
                                        ? AppColors.shieldGreen
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    })(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.shieldGreen : AppColors.lightGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.small.copyWith(
            color: isSelected ? AppColors.white : AppColors.darkGray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 8),
          Text(amount, style: AppTypography.h4.copyWith(color: color)),
        ],
      ),
    );
  }
}
