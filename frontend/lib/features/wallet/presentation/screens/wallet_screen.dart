import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/wallet.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/demo_support.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        child: AppPageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Available Balance',
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${dummyWallet.currentBalance.toStringAsFixed(2)}',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.shieldNavy,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Recharge Wallet',
                            onPressed: () {
                              context.go('/demo/customer/recharge');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Credits',
                      amount: '₹7,000.00',
                      color: AppColors.shieldGreen,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Total Debits',
                      amount: '₹2,050.00',
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transaction History', style: AppTypography.h4),
                  TextButton(
                    onPressed: () {
                      context.go('/transactions');
                    },
                    child: Text(
                      'View All',
                      style: AppTypography.small.copyWith(
                        color: AppColors.shieldBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...dummyTransactions.map((txn) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      showDemoDetailsSheet(
                        context,
                        title: txn.remarks ?? 'Wallet transaction',
                        subtitle:
                            'A ${txn.transactionType.toLowerCase()} entry of ₹${txn.amount.toStringAsFixed(2)} was recorded in the demo ledger.',
                        meta:
                            '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year}',
                        status: txn.transactionType,
                        highlights: [
                          'Running balance after this transaction is ₹${txn.postBalance.toStringAsFixed(2)}.',
                          'This entry stays visible to demonstrate the ledger-based wallet model from the docs.',
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
                                ? AppColors.shieldGreen.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                txn.remarks ?? 'Transaction',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year} • ${txn.createdAt.hour}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
                                style: AppTypography.tiny.copyWith(
                                  color: AppColors.gray,
                                ),
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
              }),
            ],
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
