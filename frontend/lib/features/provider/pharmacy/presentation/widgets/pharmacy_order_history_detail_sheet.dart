import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';

class PharmacyOrderHistoryDetailSheet extends StatelessWidget {
  final PharmacyOrderModel order;

  const PharmacyOrderHistoryDetailSheet({
    super.key,
    required this.order,
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
    final customer = order.customer;
    final customerName = customer?.fullName ?? 'Customer';
    final customerCode = customer?.customerCode ?? 'N/A';
    final customerPhone = customer?.mobile ?? '';
    final discountAmount = order.totalAmount - order.payableAmount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order History Detail',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.shieldNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.orderNumber.isNotEmpty
                          ? order.orderNumber
                          : 'ORD-${order.id}',
                      style: AppTypography.caption.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status & Fulfillment Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusBgColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusBgColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle_outlined
                            : isCancelled || isRejected
                                ? Icons.cancel_outlined
                                : Icons.info_outline,
                        color: statusTextColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Terminal Status: ${order.status}',
                        style: AppTypography.subtitle2.copyWith(
                          color: statusTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPaid ? AppColors.mintGreen : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Payment: ${order.paymentStatus}',
                      style: AppTypography.caption.copyWith(
                        color: isPaid ? AppColors.shieldGreen : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer Details
            Text(
              'Customer Information',
              style: AppTypography.subtitle2.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.shieldNavy.withValues(alpha: 0.1),
                child: const Icon(Icons.person_outline, color: AppColors.shieldNavy),
              ),
              title: Text(customerName, style: AppTypography.subtitle2),
              subtitle: Text(
                'Code: $customerCode • Mobile: $customerPhone',
                style: AppTypography.caption,
              ),
            ),
            const Divider(height: 20),

            // Delivery Address Snapshot (if HOME_DELIVERY)
            if (order.isHomeDelivery &&
                order.deliveryAddress != null &&
                order.deliveryAddress!.isNotEmpty) ...[
              Text(
                'Delivery Address',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.deliveryAddress!,
                  style: AppTypography.caption,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Cancellation / Rejection Reason
            if ((isCancelled || isRejected) &&
                order.cancellationReason != null &&
                order.cancellationReason!.isNotEmpty) ...[
              Text(
                'Reason for Cancellation / Rejection',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  order.cancellationReason!,
                  style: AppTypography.caption.copyWith(
                    color: Colors.red.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Items List / Table
            Text(
              'Order Items (${order.items.length})',
              style: AppTypography.subtitle2.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Item', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                        Text('Qty x Price', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                        Text('Total', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppTypography.caption,
                            ),
                          ),
                          Text(
                            '${item.quantity} x ₹${item.unitPrice.toStringAsFixed(2)}',
                            style: AppTypography.caption,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '₹${item.lineTotal.toStringAsFixed(2)}',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Financial Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.shieldLightBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal Amount', style: AppTypography.caption),
                      Text('₹ ${order.totalAmount.toStringAsFixed(2)}',
                          style: AppTypography.caption),
                    ],
                  ),
                  if (discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discount', style: AppTypography.caption),
                        Text('- ₹ ${discountAmount.toStringAsFixed(2)}',
                            style: AppTypography.caption.copyWith(color: AppColors.shieldGreen)),
                      ],
                    ),
                  ],
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Authoritative Payable Amount',
                        style: AppTypography.subtitle2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.shieldNavy,
                        ),
                      ),
                      Text(
                        '₹ ${order.payableAmount.toStringAsFixed(2)}',
                        style: AppTypography.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.shieldNavy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Read-Only Footer Banner
            Center(
              child: Text(
                'Historical Record • Read-Only View',
                style: AppTypography.caption.copyWith(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
