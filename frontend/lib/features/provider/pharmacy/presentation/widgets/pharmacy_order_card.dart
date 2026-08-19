import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';

class PharmacyOrderCard extends StatelessWidget {
  final PharmacyOrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final bool isActionLoading;

  const PharmacyOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.isActionLoading = false,
  });

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
      case 'SUBMITTED':
      case 'REQUESTED':
      case 'NEW':
        return Colors.orange.shade800;
      case 'ACCEPTED':
      case 'REVIEWING':
        return AppColors.shieldBlue;
      case 'PREPARING':
      case 'PROCESSING':
        return Colors.purple.shade700;
      case 'READY':
      case 'READY_FOR_PICKUP':
      case 'OUT_FOR_DELIVERY':
      case 'DELIVERY':
        return AppColors.shieldGreen;
      case 'COMPLETED':
      case 'DELIVERED':
      case 'COLLECTED':
        return AppColors.shieldGreen;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red.shade700;
      default:
        return AppColors.charcoal;
    }
  }

  Color _statusBg(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
      case 'SUBMITTED':
      case 'REQUESTED':
      case 'NEW':
        return Colors.orange.shade50;
      case 'ACCEPTED':
      case 'REVIEWING':
        return AppColors.shieldLightBlue;
      case 'PREPARING':
      case 'PROCESSING':
        return Colors.purple.shade50;
      case 'READY':
      case 'READY_FOR_PICKUP':
      case 'OUT_FOR_DELIVERY':
      case 'DELIVERY':
        return AppColors.mintGreen;
      case 'COMPLETED':
      case 'DELIVERED':
      case 'COLLECTED':
        return AppColors.mintGreen;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _sourceIcon(String source) {
    switch (source.toUpperCase()) {
      case 'PRESCRIPTION':
        return Icons.description_outlined;
      case 'WELLNESS':
        return Icons.spa_outlined;
      case 'MANUAL_ITEMS':
      default:
        return Icons.edit_note_rounded;
    }
  }

  String _sourceLabel(String source) {
    switch (source.toUpperCase()) {
      case 'PRESCRIPTION':
        return 'Rx Upload';
      case 'WELLNESS':
        return 'Wellness';
      case 'MANUAL_ITEMS':
      default:
        return 'Typed List';
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName = order.customer?.fullName ?? 'Walk-in Customer';
    final mobile = order.customer?.mobile ?? '';
    final timeStr =
        '${order.submittedAt.hour.toString().padLeft(2, '0')}:${order.submittedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Order # & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.shieldLightBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _sourceIcon(order.orderSource),
                          size: 16,
                          color: AppColors.shieldNavy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.orderNumber,
                        style: AppTypography.subtitle2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.shieldNavy,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusBg(order.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.replaceAll('_', ' '),
                      style: AppTypography.caption.copyWith(
                        color: _statusColor(order.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: Customer Name & Phone
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customerName,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (mobile.isNotEmpty) ...[
                    Text(
                      mobile,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Row 3: Fulfillment Preference & Item Count / Prescription
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: order.isHomeDelivery
                          ? Colors.blue.shade50
                          : Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          order.isHomeDelivery
                              ? Icons.local_shipping_outlined
                              : Icons.storefront_outlined,
                          size: 13,
                          color: order.isHomeDelivery
                              ? Colors.blue.shade800
                              : Colors.teal.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.isHomeDelivery ? 'Delivery' : 'Pickup',
                          style: AppTypography.caption.copyWith(
                            color: order.isHomeDelivery
                                ? Colors.blue.shade800
                                : Colors.teal.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _sourceLabel(order.orderSource),
                      style: AppTypography.caption.copyWith(
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              // Row 4: Primary Action Button if provided
              if (onPrimaryAction != null && primaryActionLabel != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: isActionLoading ? null : onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.shieldNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: isActionLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sync_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  primaryActionLabel!,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body2.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            primaryActionLabel!,
                            style: AppTypography.body2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
