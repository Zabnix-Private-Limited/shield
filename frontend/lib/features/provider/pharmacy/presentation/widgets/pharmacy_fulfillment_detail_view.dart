import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_orders_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_status_chip.dart';
import 'package:shield/shared/utils/prescription_file_picker.dart';

class PharmacyFulfillmentDetailView extends StatefulWidget {
  final PharmacyOrderModel order;
  final VoidCallback? onClose;

  const PharmacyFulfillmentDetailView({
    super.key,
    required this.order,
    this.onClose,
  });

  @override
  State<PharmacyFulfillmentDetailView> createState() =>
      _PharmacyFulfillmentDetailViewState();
}

class _PharmacyFulfillmentDetailViewState
    extends State<PharmacyFulfillmentDetailView> {
  late bool _isChronic;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _isChronic = widget.order.isChronic;
    _notesController =
        TextEditingController(text: widget.order.pharmacistNotes ?? '');
  }

  @override
  void didUpdateWidget(covariant PharmacyFulfillmentDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _isChronic = widget.order.isChronic;
      _notesController.text = widget.order.pharmacistNotes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showSubstituteModal(BuildContext context, PharmacyOrderItem item) {
    final nameController = TextEditingController(text: '${item.name} Alt');
    final priceController =
        TextEditingController(text: (item.unitPrice * 0.9).toStringAsFixed(2));
    final reasonController = TextEditingController(
        text: 'Original brand unavailable; therapeutically equivalent substitute offered.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Suggest Substitute for ${item.name}',
            style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Substitute Brand / Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Substitute Unit Price (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Substitution Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          PharmacyPrimaryButton(
            label: 'Apply Substitute',
            compact: true,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final subPrice = double.tryParse(priceController.text.trim()) ?? (item.unitPrice * 0.9);
              final success = await PharmacyOrdersController.instance.updateOrderItemFulfillment(
                orderId: widget.order.id,
                itemId: item.id,
                decisionStatus: 'SUBSTITUTED',
                substituteName: nameController.text.trim(),
                substituteUnitPrice: subPrice,
                decisionReason: reasonController.text.trim(),
              );
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Substitute "${nameController.text.trim()}" saved for ${item.name}.'
                      : 'Failed to save substitute: ${PharmacyOrdersController.instance.error}'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPartialFulfillModal(BuildContext context, PharmacyOrderItem item) {
    final qtyController = TextEditingController(
      text: (item.availableQuantity > 0 ? item.availableQuantity : 1).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Partial Fulfillment for ${item.name}',
            style: PharmacyTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requested quantity: ${item.quantity.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fulfilled Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          PharmacyPrimaryButton(
            label: 'Confirm Partial',
            compact: true,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final qty = double.tryParse(qtyController.text.trim()) ?? 1.0;
              final success = await PharmacyOrdersController.instance.updateOrderItemFulfillment(
                orderId: widget.order.id,
                itemId: item.id,
                fulfillQuantity: qty,
                stockStatus: 'LOW_STOCK',
                decisionStatus: 'PARTIAL',
                decisionReason: 'Partial quantity fulfilled due to stock availability.',
              );
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Partial quantity ($qty) approved for ${item.name}.'
                      : 'Failed to update item: ${PharmacyOrdersController.instance.error}'),
                ),
              );
            },
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header Panel
          PharmacyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order.orderNumber,
                                style: PharmacyTypography.h2,
                              ),
                              const SizedBox(width: 10),
                              PharmacyStatusChip(status: order.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed: ${order.submittedAt.day}/${order.submittedAt.month}/${order.submittedAt.year} ${order.submittedAt.hour.toString().padLeft(2, '0')}:${order.submittedAt.minute.toString().padLeft(2, '0')} • Source: ${order.orderSource}',
                            style: PharmacyTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    if (widget.onClose != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: widget.onClose,
                      ),
                  ],
                ),
                const Divider(height: 24),

                // Customer & Fulfillment Info Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer Details',
                              style: PharmacyTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PharmacyColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(order.customer?.fullName ?? 'Walk-in Customer',
                              style: PharmacyTypography.subtitle
                                  .copyWith(fontWeight: FontWeight.bold)),
                          if (order.customer?.mobile.isNotEmpty ?? false)
                            Text('Phone: ${order.customer!.mobile}',
                                style: PharmacyTypography.caption),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fulfillment Preference',
                              style: PharmacyTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PharmacyColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(order.displayFulfillment,
                              style: PharmacyTypography.subtitle
                                  .copyWith(fontWeight: FontWeight.bold)),
                          if (order.isHomeDelivery &&
                              order.deliveryAddress != null)
                            Text('Address: ${order.deliveryAddress}',
                                style: PharmacyTypography.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Chronic Tagging Switch
                    Column(
                      children: [
                        Text('Chronic Order',
                            style: PharmacyTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: PharmacyColors.textSecondary)),
                        Switch(
                          value: _isChronic,
                          activeTrackColor: PharmacyColors.primary,
                          onChanged: (val) async {
                            setState(() => _isChronic = val);
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await PharmacyOrdersController.instance.toggleChronicOrder(
                              orderId: widget.order.id,
                              isChronic: val,
                            );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? (val ? 'Order tagged as Chronic Refill Order.' : 'Chronic tag removed.')
                                    : 'Failed to update chronic status: ${PharmacyOrdersController.instance.error}'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Per-Item Fulfillment Decision Workspace
          PharmacyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Per-Item Fulfillment & Stock Verification',
                        style: PharmacyTypography.subtitle
                            .copyWith(fontWeight: FontWeight.bold)),
                    Text('${order.items.length} items',
                        style: PharmacyTypography.caption),
                  ],
                ),
                const SizedBox(height: 12),
                if (order.items.isEmpty) ...[
                  const PharmacyEmptyState(
                    title: 'No item lines specified',
                    subtitle:
                        'Prescription image or customer notes submitted for fulfillment.',
                    icon: Icons.assignment_outlined,
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (ctx, index) {
                      final item = order.items[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(item.name,
                                    style: PharmacyTypography.subtitle
                                        .copyWith(fontWeight: FontWeight.bold)),
                              ),
                              PharmacyStatusChip(status: item.stockStatus),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Req: ${item.quantity.toStringAsFixed(0)} • Avail: ${item.availableQuantity.toStringAsFixed(0)} • Unit: ₹${item.unitPrice.toStringAsFixed(2)}',
                                  style: PharmacyTypography.caption),
                              Text('Total: ₹${item.lineTotal.toStringAsFixed(2)}',
                                  style: PharmacyTypography.subtitle.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: PharmacyColors.navy)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Item Action Buttons
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              PharmacySecondaryButton(
                                label: 'Approve Full',
                                compact: true,
                                icon: Icons.check_circle_outline,
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final success = await PharmacyOrdersController.instance.updateOrderItemFulfillment(
                                    orderId: widget.order.id,
                                    itemId: item.id,
                                    fulfillQuantity: item.quantity,
                                    stockStatus: 'FULL_STOCK',
                                    decisionStatus: 'APPROVED',
                                    decisionReason: 'Fully stock approved by pharmacist.',
                                  );
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(success
                                          ? 'Full quantity approved for ${item.name}.'
                                          : 'Failed to approve item: ${PharmacyOrdersController.instance.error}'),
                                    ),
                                  );
                                },
                              ),
                              if (item.availableQuantity < item.quantity &&
                                  item.availableQuantity > 0)
                                PharmacySecondaryButton(
                                  label: 'Partial Fulfill',
                                  compact: true,
                                  icon: Icons.remove_circle_outline,
                                  onPressed: () => _showPartialFulfillModal(context, item),
                                ),
                              PharmacySecondaryButton(
                                label: 'Suggest Substitute',
                                compact: true,
                                icon: Icons.swap_horiz_rounded,
                                onPressed: () =>
                                    _showSubstituteModal(context, item),
                              ),
                              PharmacyDangerButton(
                                label: 'Reject Item',
                                compact: true,
                                icon: Icons.cancel_outlined,
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final success = await PharmacyOrdersController.instance.updateOrderItemFulfillment(
                                    orderId: widget.order.id,
                                    itemId: item.id,
                                    fulfillQuantity: 0,
                                    stockStatus: 'OUT_OF_STOCK',
                                    decisionStatus: 'REJECTED',
                                    decisionReason: 'Item unavailable or out of stock.',
                                  );
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(success
                                          ? '${item.name} rejected from order fulfillment.'
                                          : 'Failed to reject item: ${PharmacyOrdersController.instance.error}'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pharmacist Notes & Invoice Upload Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notes Column
              Expanded(
                child: PharmacyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pharmacist Notes & Remarks',
                          style: PharmacyTypography.subtitle
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Enter internal fulfillment notes, storage instructions, or customer remarks...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      PharmacySecondaryButton(
                        label: 'Save Notes',
                        compact: true,
                        icon: Icons.save_outlined,
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await PharmacyOrdersController.instance.savePharmacistNotes(
                            orderId: widget.order.id,
                            notes: _notesController.text.trim(),
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Pharmacist notes saved.'
                                  : 'Failed to save notes: ${PharmacyOrdersController.instance.error}'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Invoice Upload Column
              Expanded(
                child: PharmacyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bill & Invoice Management',
                          style: PharmacyTypography.subtitle
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (order.invoiceFileName != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: PharmacyColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: PharmacyColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, color: PharmacyColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      order.invoiceFileName!,
                                      style: PharmacyTypography.caption.copyWith(fontWeight: FontWeight.bold, color: PharmacyColors.navy),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: order.invoiceSentAt != null ? PharmacyColors.successBg : PharmacyColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      order.invoiceSentAt != null ? 'SENT TO CUSTOMER' : 'UPLOADED',
                                      style: PharmacyTypography.tiny.copyWith(
                                        color: order.invoiceSentAt != null ? PharmacyColors.successText : PharmacyColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (order.invoiceSentAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Sent on ${order.invoiceSentAt!.toIso8601String().split('T').first}',
                                  style: PharmacyTypography.tiny.copyWith(color: PharmacyColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          PharmacySecondaryButton(
                            label: order.invoiceFileName != null
                                ? 'Replace'
                                : 'Upload Bill / Invoice',
                            compact: true,
                            icon: Icons.upload_file_rounded,
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final file = await pickPrescriptionFile();
                              if (file == null) return;
                              final success = await PharmacyOrdersController.instance.uploadOrderInvoiceFile(
                                orderId: widget.order.id,
                                bytes: file.bytes,
                                fileName: file.name,
                              );
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Invoice "${file.name}" uploaded successfully.'
                                      : 'Failed to upload invoice: ${PharmacyOrdersController.instance.error}'),
                                ),
                              );
                            },
                          ),
                          if (order.invoiceFileName != null) ...[
                            PharmacyDangerButton(
                              label: 'Remove',
                              compact: true,
                              icon: Icons.delete_outline_rounded,
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final success = await PharmacyOrdersController.instance.removeOrderInvoice(
                                  orderId: widget.order.id,
                                );
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Invoice removed.'
                                        : 'Failed to remove invoice: ${PharmacyOrdersController.instance.error}'),
                                  ),
                                );
                              },
                            ),
                          ],
                          PharmacyPrimaryButton(
                            label: 'Send Invoice',
                            compact: true,
                            icon: Icons.send_rounded,
                            onPressed: order.invoiceFileName == null
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final success = await PharmacyOrdersController.instance.sendOrderInvoice(
                                      orderId: widget.order.id,
                                    );
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(success
                                            ? 'Invoice sent to customer notification channel.'
                                            : 'Failed to send invoice: ${PharmacyOrdersController.instance.error}'),
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Primary Contextual Order Actions Bar
          PharmacyCard(
            color: PharmacyColors.surfaceSubtle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Payable: ₹ ${order.payableAmount.toStringAsFixed(2)}',
                        style: PharmacyTypography.h3),
                    Text('Payment Status: ${order.paymentStatus}',
                        style: PharmacyTypography.caption),
                  ],
                ),
                if (isUpdating)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: PharmacyColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync_rounded, size: 16, color: PharmacyColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Updating fulfillment state...',
                          style: PharmacyTypography.caption.copyWith(
                            color: PharmacyColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    children: [
                      if (order.status == 'PLACED' ||
                          order.status == 'SUBMITTED' ||
                          order.status == 'NEW')
                        PharmacyPrimaryButton(
                          label: 'Approve Order',
                          icon: Icons.check_circle_rounded,
                          onPressed: () =>
                              PharmacyOrdersController.instance.updateOrderStatus(
                            orderId: order.id,
                            nextStatus: 'ACCEPTED',
                          ),
                        ),
                      if (order.status == 'ACCEPTED')
                        PharmacyPrimaryButton(
                          label: 'Start Preparing',
                          icon: Icons.hourglass_top_rounded,
                          onPressed: () =>
                              PharmacyOrdersController.instance.updateOrderStatus(
                            orderId: order.id,
                            nextStatus: 'PREPARING',
                          ),
                        ),
                      if (order.status == 'PREPARING')
                        PharmacyPrimaryButton(
                          label: order.isHomeDelivery
                              ? 'Dispatch Partial/Full'
                              : 'Ready for Pickup',
                          icon: order.isHomeDelivery
                              ? Icons.local_shipping_rounded
                              : Icons.storefront_rounded,
                          onPressed: () =>
                              PharmacyOrdersController.instance.updateOrderStatus(
                            orderId: order.id,
                            nextStatus: order.isHomeDelivery
                                ? 'OUT_FOR_DELIVERY'
                                : 'READY_FOR_PICKUP',
                          ),
                        ),
                      if (order.status == 'READY_FOR_PICKUP' ||
                          order.status == 'OUT_FOR_DELIVERY')
                        PharmacyPrimaryButton(
                          label: 'Mark Order Completed',
                          icon: Icons.task_alt_rounded,
                          onPressed: () =>
                              PharmacyOrdersController.instance.updateOrderStatus(
                            orderId: order.id,
                            nextStatus: 'COMPLETED',
                          ),
                        ),
                      if (order.status != 'COMPLETED' &&
                          order.status != 'CANCELLED')
                        PharmacyDangerButton(
                          label: 'Reject Order',
                          icon: Icons.cancel_outlined,
                          onPressed: () =>
                              PharmacyOrdersController.instance.updateOrderStatus(
                            orderId: order.id,
                            nextStatus: 'CANCELLED',
                            cancellationReason: 'Rejected by Pharmacy',
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
