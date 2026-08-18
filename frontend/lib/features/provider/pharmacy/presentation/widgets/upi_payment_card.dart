import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_method_model.dart';

class UpiPaymentCard extends StatelessWidget {
  final PharmacyPaymentMethodModel method;
  final VoidCallback onEdit;
  final VoidCallback onUploadQr;
  final VoidCallback? onRemoveQr;
  final VoidCallback onToggleActive;
  final VoidCallback? onSetPrimary;
  final bool isUpdating;

  const UpiPaymentCard({
    super.key,
    required this.method,
    required this.onEdit,
    required this.onUploadQr,
    this.onRemoveQr,
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
              ? AppColors.shieldGreen
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
            // Header Row: UPI & Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 20,
                        color: AppColors.shieldGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.upiId ?? 'UPI Method',
                          style: AppTypography.subtitle2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.shieldNavy,
                          ),
                        ),
                        if (method.displayLabel != null &&
                            method.displayLabel!.isNotEmpty)
                          Text(
                            method.displayLabel!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.charcoal,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (method.isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.mintGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Primary',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.shieldGreen,
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

            // QR Image Preview / Placeholder
            if (method.qrImageUrl != null) ...[
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    method.qrImageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined, size: 36),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: isUpdating ? null : onUploadQr,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Replace QR'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (onRemoveQr != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: isUpdating ? null : onRemoveQr,
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: const Text('Remove QR'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: isUpdating ? null : onUploadQr,
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: const Text('Upload QR Image'),
              ),
            ],
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
                      foregroundColor: AppColors.shieldGreen,
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
