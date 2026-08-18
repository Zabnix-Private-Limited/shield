import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';

class PharmacyOrderHistoryCard extends StatelessWidget {
  final PharmacyOrderModel order;
  final VoidCallback onTapDetail;

  const PharmacyOrderHistoryCard({
    super.key,
    required this.order,
    required this.onTapDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = order.status == 'COMPLETED';
    final isCancelled = order.status == 'CANCELLED';
    final isRejected = order.status == 'REJECTED';

    final statusBgColor = isCompleted
        ? AppColors.mintGreen
        : isCancelled || isRejected
            ? Colors.red.shade100
            : Colors.grey.shade200;

    final statusTextColor = isCompleted
        ? AppColors.shieldGreen
        : isCancelled || isRejected
            ? Colors.red.shade800
            : AppColors.charcoal;

    final isPaid = order.paymentStatus.toUpperCase() == 'PAID';
    final customerName = order.customer?.fullName ?? 'Customer';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTapDetail,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Order # & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.shieldLightBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          size: 20,
                          color: AppColors.shieldNavy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber.isNotEmpty
                                ? order.orderNumber
                                : 'ORD-${order.id}',
                            style: AppTypography.subtitle2.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.shieldNavy,
                            ),
                          ),
                          Text(
                            customerName,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.charcoal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status,
                      style: AppTypography.caption.copyWith(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chips Row: Source & Fulfillment
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(
                      order.orderSource.replaceAll('_', ' '),
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                    backgroundColor: AppColors.shieldLightBlue.withValues(alpha: 0.15),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Chip(
                    label: Text(
                      order.displayFulfillment,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: AppColors.charcoal,
                      ),
                    ),
                    backgroundColor: Colors.grey.shade100,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Item Count & Amounts Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Amount', style: AppTypography.caption),
                      Text(
                        '₹ ${order.payableAmount.toStringAsFixed(2)}',
                        style: AppTypography.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.shieldNavy,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Payment Status', style: AppTypography.caption),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid ? AppColors.mintGreen : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.paymentStatus,
                          style: AppTypography.caption.copyWith(
                            color: isPaid ? AppColors.shieldGreen : Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),

              // Bottom Row: Date & Read-only Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${order.submittedAt.day}/${order.submittedAt.month}/${order.submittedAt.year}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onTapDetail,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View History Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
