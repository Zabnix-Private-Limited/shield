import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/wallet.dart';
import '../../../../../shared/utils/app_display_formatters.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/portal_support.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final accent = isCredit ? AppColors.shieldGreen : AppColors.error;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => showPortalDetailsSheet(
        context,
        title: transaction.remarks ?? 'Wallet transaction',
        subtitle:
            '${_ledgerLabel(transaction.subLedgerType)} ${_displayType(transaction.ledgerEntryType)} for ${AppDisplayFormatters.formatCurrencyString(transaction.amount.toStringAsFixed(2))}.',
        meta: AppDisplayFormatters.formatDateOrDateTime(
          transaction.createdAt.toIso8601String(),
        ),
        status: transaction.status ?? _displayType(transaction.ledgerEntryType),
        highlights: [
          'Cash Wallet shows CASH-ledger entries only.',
          if (transaction.referenceType?.trim().isNotEmpty == true)
            'Reference: ${transaction.referenceType}${transaction.referenceId?.trim().isNotEmpty == true ? ' · ${transaction.referenceId}' : ''}',
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
                  AppDisplayFormatters.formatDateOrDateTime(
                    transaction.createdAt.toIso8601String(),
                  ),
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${AppDisplayFormatters.formatCurrencyString(transaction.amount.toStringAsFixed(2))}',
                style: AppTypography.body.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              _LedgerBadge(label: _displayType(transaction.ledgerEntryType)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerBadge extends StatelessWidget {
  const _LedgerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = label.toUpperCase().contains('REVERSAL')
        ? AppColors.warning
        : AppColors.shieldBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: palette,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _ledgerLabel(String ledgerType) =>
    ledgerType == 'CASH' ? 'cash wallet' : ledgerType.toLowerCase();

String _displayType(String value) => value
    .toLowerCase()
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');
