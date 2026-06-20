import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/wallet.dart';
import '../../../../shared/widgets/app_card.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummyTransactions.length,
        itemBuilder: (context, index) {
          final txn = dummyTransactions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              onTap: () {},
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
                      txn.transactionType == 'CREDIT' ? Icons.add : Icons.remove,
                      color: txn.transactionType == 'CREDIT' ? AppColors.shieldGreen : AppColors.error,
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
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year} • ${txn.createdAt.hour}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
                          style: AppTypography.tiny.copyWith(color: AppColors.gray),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Transaction ID: ${txn.id}',
                          style: AppTypography.tiny.copyWith(color: AppColors.gray.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${txn.transactionType == 'CREDIT' ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                        style: AppTypography.h4.copyWith(
                          color: txn.transactionType == 'CREDIT' ? AppColors.shieldGreen : AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Balance: ₹${txn.postBalance.toStringAsFixed(2)}',
                        style: AppTypography.tiny.copyWith(color: AppColors.gray),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
