import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_method_model.dart';

class BankAccountCard extends StatelessWidget {
  final PharmacyPaymentMethodModel method;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback? onSetPrimary;
  final bool isUpdating;

  const BankAccountCard({
    super.key,
    required this.method,
    required this.onEdit,
    required this.onToggleActive,
    this.onSetPrimary,
    this.isUpdating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: method.isPrimary
              ? AppColors.shieldBlue
              : method.isActive
                  ? Colors.grey.shade200
                  : Colors.grey.shade300,
          width: method.isPrimary ? 1.5 : 1,
        ),
      ),
      color: method.isActive ? Colors.white : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Bank Name & Primary / Active Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.shieldLightBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_outlined,
                          size: 20,
                          color: AppColors.shieldNavy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.bankName ?? 'Bank Account',
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.subtitle2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.shieldNavy,
                              ),
                            ),
                            if (method.displayLabel != null &&
                                method.displayLabel!.isNotEmpty)
                              Text(
                                method.displayLabel!,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.charcoal,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    if (method.isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.shieldBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Primary',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.shieldBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (!method.isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Inactive',
                          style: AppTypography.caption.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Account Details
            Text(
              method.maskedAccountNumber ?? '••••',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                Text(
                  'IFSC: ${method.ifscCode ?? 'N/A'}',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (method.branchName != null &&
                    method.branchName!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Branch: ${method.branchName}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Holder: ${method.accountHolderName ?? 'N/A'}',
              style: AppTypography.caption.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const Divider(height: 20),

            // Action Buttons Row
            Row(
              children: [
                if (!method.isPrimary && method.isActive && onSetPrimary != null)
                  TextButton.icon(
                    onPressed: isUpdating ? null : onSetPrimary,
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Set Primary'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.shieldBlue,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: isUpdating ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: isUpdating ? null : onToggleActive,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        method.isActive ? Colors.red.shade700 : AppColors.shieldGreen,
                  ),
                  child: Text(method.isActive ? 'Deactivate' : 'Reactivate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
