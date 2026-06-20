import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/wallet.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final customer = dummyCustomers.first;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHIELD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.go('/notifications');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${customer.firstName}!',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 24),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${dummyWallet.currentBalance.toStringAsFixed(2)}',
                    style: AppTypography.h2.copyWith(color: AppColors.shieldNavy),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Recharge',
                          type: AppButtonType.outline,
                          onPressed: () {},
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'View Wallet',
                          onPressed: () {
                            context.go('/wallet');
                          },
                          height: 48,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: AppTypography.h4,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                const QuickActionCard(icon: Icons.qr_code_scanner, label: 'QR Scan'),
                const QuickActionCard(icon: Icons.receipt_long, label: 'Payments'),
                QuickActionCard(
                  icon: Icons.event_available,
                  label: 'Appointments',
                  onTap: () {
                    context.go('/appointments');
                  },
                ),
                QuickActionCard(
                  icon: Icons.description,
                  label: 'Documents',
                  onTap: () {
                    context.go('/documents');
                  },
                ),
                QuickActionCard(
                  icon: Icons.medical_services,
                  label: 'Prescriptions',
                  onTap: () {
                    context.go('/prescriptions');
                  },
                ),
                const QuickActionCard(icon: Icons.support_agent, label: 'Support'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: AppTypography.h5,
                ),
                TextButton(
                  onPressed: () {
                    context.go('/transactions');
                  },
                  child: Text(
                    'View All',
                    style: AppTypography.small.copyWith(color: AppColors.shieldBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...dummyTransactions.take(3).map((txn) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: txn.transactionType == 'CREDIT' 
                            ? AppColors.shieldGreen.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          txn.transactionType == 'CREDIT' ? Icons.add : Icons.remove,
                          color: txn.transactionType == 'CREDIT' ? AppColors.shieldGreen : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn.remarks ?? 'Transaction',
                              style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year}',
                              style: AppTypography.tiny.copyWith(color: AppColors.gray),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${txn.transactionType == 'CREDIT' ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: txn.transactionType == 'CREDIT' ? AppColors.shieldGreen : AppColors.error,
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
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.shieldBlue),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.tiny,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
