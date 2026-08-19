import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_orders_controller.dart';
import 'package:shield/shared/widgets/portal_support.dart';

class PharmacyOrderDetailSheet extends StatefulWidget {
  final PharmacyOrderModel order;
  final VoidCallback onClose;

  const PharmacyOrderDetailSheet({
    super.key,
    required this.order,
    required this.onClose,
  });

  @override
  State<PharmacyOrderDetailSheet> createState() =>
      _PharmacyOrderDetailSheetState();
}

class _PharmacyOrderDetailSheetState extends State<PharmacyOrderDetailSheet> {
  final TextEditingController _cancellationReasonController =
      TextEditingController();

  @override
  void dispose() {
    _cancellationReasonController.dispose();
    super.dispose();
  }

  void _showCancellationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel / Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for cancelling or rejecting this order:',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cancellationReasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Out of stock, invalid prescription image...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = _cancellationReasonController.text.trim();
              Navigator.pop(ctx);
              await PharmacyOrdersController.instance.updateOrderStatus(
                orderId: widget.order.id,
                nextStatus: 'CANCELLED',
                cancellationReason: reason.isNotEmpty ? reason : 'Cancelled by pharmacy',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isUpdating =
        PharmacyOrdersController.instance.isOrderUpdating(order.id);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(20),
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
                      order.orderNumber,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.shieldNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Submitted: ${order.submittedAt.day}/${order.submittedAt.month}/${order.submittedAt.year} ${order.submittedAt.hour.toString().padLeft(2, '0')}:${order.submittedAt.minute.toString().padLeft(2, '0')}',
                      style: AppTypography.caption.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const Divider(height: 24),

            // Section 1: Customer Details
            Text(
              'Customer Information',
              style: AppTypography.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customer?.fullName ?? 'Walk-in Customer',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (order.customer?.mobile.isNotEmpty ?? false)
                    Text('Phone: ${order.customer!.mobile}'),
                  if (order.customer?.customerCode != null)
                    Text('Code: ${order.customer!.customerCode}'),
                  if (order.isHomeDelivery && order.deliveryAddress != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Delivery Address:',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    Text(order.deliveryAddress!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Order Content (Prescription / Items)
            Text(
              'Order Request Details',
              style: AppTypography.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (order.isPrescription) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Text(
                          'Prescription Order',
                          style: AppTypography.body1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    if (order.customerNotes != null) ...[
                      const SizedBox(height: 6),
                      Text('Customer Note: "${order.customerNotes}"'),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Open prescription attachment preview
                        showPortalSnackBar(
                          context,
                          'Opening prescription document attachment preview...',
                        );
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('View Prescription Attachment'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.isEmpty ? 1 : order.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (order.items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          order.customerNotes ?? 'Requested items list',
                        ),
                      );
                    }
                    final item = order.items[index];
                    return ListTile(
                      dense: true,
                      title: Text(item.name, style: AppTypography.body2.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('Qty: ${item.quantity.toStringAsFixed(0)} × ₹${item.unitPrice.toStringAsFixed(2)}'),
                      trailing: Text(
                        '₹${item.lineTotal.toStringAsFixed(2)}',
                        style: AppTypography.body2.copyWith(fontWeight: FontWeight.bold, color: AppColors.shieldNavy),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Section 3: Fulfillment Transition Actions
            Text(
              'Order Status Actions',
              style: AppTypography.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            if (isUpdating) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.shieldLightBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync_rounded, size: 16, color: AppColors.shieldNavy),
                    const SizedBox(width: 8),
                    Text(
                      'Updating order status...',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.shieldNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (order.status == 'PLACED' ||
                      order.status == 'SUBMITTED' ||
                      order.status == 'REQUESTED') ...[
                    ElevatedButton.icon(
                      onPressed: () =>
                          PharmacyOrdersController.instance.updateOrderStatus(
                        orderId: order.id,
                        nextStatus: 'ACCEPTED',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.shieldBlue,
                      ),
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: const Text('Accept Order',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  if (order.status == 'ACCEPTED') ...[
                    ElevatedButton.icon(
                      onPressed: () =>
                          PharmacyOrdersController.instance.updateOrderStatus(
                        orderId: order.id,
                        nextStatus: 'PREPARING',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                      ),
                      icon: const Icon(Icons.inventory_2_outlined,
                          color: Colors.white),
                      label: const Text('Start Preparing',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  if (order.status == 'PREPARING') ...[
                    ElevatedButton.icon(
                      onPressed: () =>
                          PharmacyOrdersController.instance.updateOrderStatus(
                        orderId: order.id,
                        nextStatus: order.isHomeDelivery
                            ? 'OUT_FOR_DELIVERY'
                            : 'READY_FOR_PICKUP',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.shieldGreen,
                      ),
                      icon: Icon(
                        order.isHomeDelivery
                            ? Icons.local_shipping
                            : Icons.storefront,
                        color: Colors.white,
                      ),
                      label: Text(
                        order.isHomeDelivery
                            ? 'Dispatch Delivery'
                            : 'Ready for Pickup',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  if (order.status == 'READY_FOR_PICKUP' ||
                      order.status == 'OUT_FOR_DELIVERY' ||
                      order.status == 'READY') ...[
                    ElevatedButton.icon(
                      onPressed: () =>
                          PharmacyOrdersController.instance.updateOrderStatus(
                        orderId: order.id,
                        nextStatus: 'COMPLETED',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.shieldGreen,
                      ),
                      icon: const Icon(Icons.task_alt, color: Colors.white),
                      label: const Text('Mark Completed',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  if (order.status != 'COMPLETED' &&
                      order.status != 'CANCELLED') ...[
                    OutlinedButton.icon(
                      onPressed: () => _showCancellationDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel / Reject'),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
