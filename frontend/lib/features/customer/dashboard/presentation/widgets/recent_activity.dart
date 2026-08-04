import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/wallet.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key, required this.transactions});

  final List<WalletTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const EmptyState(
        title: 'No recent activity',
        message: 'Wallet activity will appear here after a completed entry.',
        icon: Icons.timeline_outlined,
      );
    }

    return Column(
      children: transactions
          .map(
            (txn) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            (txn.transactionType == 'CREDIT'
                                    ? AppColors.shieldGreen
                                    : AppColors.error)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        txn.transactionType == 'CREDIT'
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: txn.transactionType == 'CREDIT'
                            ? AppColors.shieldGreen
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txn.remarks ?? 'Activity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'dd MMM yyyy • hh:mm a',
                            ).format(txn.createdAt),
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${txn.transactionType == 'CREDIT' ? '+' : '-'}₹${txn.amount.toStringAsFixed(0)}',
                      style: AppTypography.body.copyWith(
                        color: txn.transactionType == 'CREDIT'
                            ? AppColors.shieldGreen
                            : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
