import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/wallet.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/portal_support.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.ledgerBalanceAfter,
  });

  final WalletTransaction transaction;
  final double Function(WalletTransaction transaction) ledgerBalanceAfter;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.transactionType == 'CREDIT';
    final accent = isCredit ? AppColors.shieldGreen : AppColors.error;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => showPortalDetailsSheet(
        context,
        title: transaction.remarks ?? 'Wallet transaction',
        subtitle:
            '${transaction.subLedgerType} ${transaction.transactionType.toLowerCase()} entry for ${transaction.amount.toStringAsFixed(0)}.',
        meta: DateFormat('dd MMM yyyy, hh:mm a').format(transaction.createdAt),
        status: transaction.transactionType,
        highlights: [
          'Post-transaction balance in ${transaction.subLedgerType} ledger is ${ledgerBalanceAfter(transaction).toStringAsFixed(0)}.',
          'This transaction is loaded from the live customer wallet ledger.',
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.remarks ?? 'Wallet transaction',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('dd MMM • hh:mm a').format(transaction.createdAt),
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
                style: AppTypography.body.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              _LedgerBadge(ledgerType: transaction.subLedgerType),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerBadge extends StatelessWidget {
  const _LedgerBadge({required this.ledgerType});

  final String ledgerType;

  @override
  Widget build(BuildContext context) {
    final palette = switch (ledgerType) {
      'POINTS' => (AppColors.warning, 'Points'),
      'BENEFIT' => (AppColors.shieldGreen, 'Benefit'),
      _ => (AppColors.shieldBlue, 'Cash'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        palette.$2,
        style: AppTypography.tiny.copyWith(
          color: palette.$1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
