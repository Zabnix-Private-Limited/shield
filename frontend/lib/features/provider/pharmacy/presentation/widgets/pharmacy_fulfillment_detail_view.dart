import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_orders_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_status_chip.dart';
import 'package:shield/shared/utils/prescription_file_picker.dart';
import 'package:shield/shared/widgets/portal_support.dart';

class PharmacyFulfillmentDetailView extends StatefulWidget {
  final PharmacyOrderModel order;
  final VoidCallback? onClose;
  final VoidCallback? onPopOver;

  const PharmacyFulfillmentDetailView({
    super.key,
    required this.order,
    this.onClose,
    this.onPopOver,
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
    _notesController = TextEditingController(
      text: widget.order.pharmacistNotes ?? '',
    );
    PharmacyOrdersController.instance.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
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
    PharmacyOrdersController.instance.removeListener(_onControllerUpdate);
    _notesController.dispose();
    super.dispose();
  }

  void _showSubstituteModal(
    BuildContext context,
    String orderId,
    PharmacyOrderItem item,
  ) {
    final nameController = TextEditingController(
      text: item.substituteName ?? '${item.name} Alt',
    );
    final priceController = TextEditingController(
      text: (item.substituteUnitPrice ?? (item.unitPrice * 0.9))
          .toStringAsFixed(2),
    );
    final reasonController = TextEditingController(
      text:
          item.decisionReason ??
          'Original brand unavailable; therapeutically equivalent substitute offered.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Suggest Substitute for ${item.name}',
          style: PharmacyTypography.subtitle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
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
              Navigator.pop(ctx);
              final subPrice =
                  double.tryParse(priceController.text.trim()) ??
                  (item.unitPrice * 0.9);
              final success = await PharmacyOrdersController.instance
                  .updateOrderItemFulfillment(
                    orderId: orderId,
                    itemId: item.id,
                    decisionStatus: 'SUBSTITUTED',
                    substituteName: nameController.text.trim(),
                    substituteUnitPrice: subPrice,
                    decisionReason: reasonController.text.trim(),
                  );
              if (!context.mounted) return;
              showPortalSnackBar(
                context,
                success
                    ? 'Substitute "${nameController.text.trim()}" saved for ${item.name}.'
                    : 'Could not save substitute: ${PharmacyOrdersController.instance.friendlyError}',
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPartialFulfillModal(
    BuildContext context,
    String orderId,
    PharmacyOrderItem item,
  ) {
    final qtyController = TextEditingController(
      text: (item.availableQuantity > 0 ? item.availableQuantity : 1)
          .toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Partial Fulfillment for ${item.name}',
          style: PharmacyTypography.subtitle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
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
              Navigator.pop(ctx);
              final qty = double.tryParse(qtyController.text.trim()) ?? 1.0;
              final success = await PharmacyOrdersController.instance
                  .updateOrderItemFulfillment(
                    orderId: orderId,
                    itemId: item.id,
                    fulfillQuantity: qty,
                    stockStatus: 'LOW_STOCK',
                    decisionStatus: 'PARTIAL',
                    decisionReason:
                        'Partial quantity fulfilled due to stock availability.',
                  );
              if (!context.mounted) return;
              showPortalSnackBar(
                context,
                success
                    ? 'Partial quantity ($qty) approved for ${item.name}.'
                    : 'Could not update item: ${PharmacyOrdersController.instance.friendlyError}',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderContextFields(
    BuildContext context,
    PharmacyOrderModel order,
  ) {
    final customer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Details',
          style: PharmacyTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: PharmacyColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          order.customer?.fullName ?? 'Walk-in Customer',
          style: PharmacyTypography.subtitle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (order.customer?.mobile.isNotEmpty ?? false)
          Text(
            'Phone: ${order.customer!.mobile}',
            style: PharmacyTypography.caption,
          ),
      ],
    );
    final fulfillment = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fulfillment Preference',
          style: PharmacyTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: PharmacyColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          order.displayFulfillment,
          style: PharmacyTypography.subtitle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (order.isHomeDelivery && order.deliveryAddress != null)
          Text(
            'Address: ${order.deliveryAddress}',
            style: PharmacyTypography.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
    final chronic = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chronic Order',
          style: PharmacyTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: PharmacyColors.textSecondary,
          ),
        ),
        Switch(
          value: _isChronic,
          activeTrackColor: PharmacyColors.primary,
          onChanged: (value) async {
            setState(() => _isChronic = value);
            final success = await PharmacyOrdersController.instance
                .toggleChronicOrder(orderId: order.id, isChronic: value);
            if (!context.mounted) return;
            showPortalSnackBar(
              context,
              success
                  ? (value
                        ? 'Order tagged as Chronic Refill Order.'
                        : 'Chronic tag removed.')
                  : 'Could not update chronic status. Please try again.',
            );
          },
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 600
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customer,
                const SizedBox(height: 16),
                fulfillment,
                const SizedBox(height: 16),
                chronic,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: customer),
                Expanded(child: fulfillment),
                chronic,
              ],
            ),
    );
  }

  Widget _buildNotesCard(PharmacyOrderModel order) => PharmacyCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pharmacist Notes & Remarks',
          style: PharmacyTypography.subtitle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(
            hintText:
                'Enter internal fulfillment notes, storage instructions, or customer remarks...',
            hintStyle: PharmacyTypography.caption,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: PharmacyColors.border),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),
        PharmacySecondaryButton(
          label: 'Save Notes',
          compact: true,
          icon: Icons.save_outlined,
          onPressed: () async {
            final success = await PharmacyOrdersController.instance
                .savePharmacistNotes(
                  orderId: order.id,
                  notes: _notesController.text.trim(),
                );
            if (!mounted) return;
            showPortalSnackBar(
              context,
              success
                  ? 'Pharmacist notes saved.'
                  : 'Could not save notes. Please try again.',
            );
          },
        ),
        if (!order.customerConfirmationRequested &&
            order.items.any((item) {
              final decision = item.decisionStatus.toUpperCase();
              return decision == 'PARTIAL' || decision == 'SUBSTITUTED';
            })) ...[
          const SizedBox(height: 8),
          PharmacyPrimaryButton(
            label: 'Request Customer Confirmation',
            compact: true,
            icon: Icons.mark_email_unread_outlined,
            onPressed: () async {
              final success = await PharmacyOrdersController.instance
                  .requestCustomerConfirmation(
                    orderId: order.id,
                    reason:
                        'Confirmation required for a partial fulfillment or substitute.',
                  );
              if (!mounted) return;
              showPortalSnackBar(
                context,
                success
                    ? 'Customer confirmation request recorded.'
                    : 'Could not request confirmation: ${PharmacyOrdersController.instance.friendlyError}',
              );
            },
          ),
        ] else if (order.customerConfirmationRequested) ...[
          const SizedBox(height: 8),
          Text(
            'Customer confirmation request is pending.',
            style: PharmacyTypography.caption.copyWith(
              color: PharmacyColors.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildInvoiceCard(PharmacyOrderModel order) => PharmacyCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bill & Invoice Management',
          style: PharmacyTypography.subtitle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (order.invoiceFileName != null) ...[
          Row(
            children: [
              const Icon(
                Icons.picture_as_pdf_rounded,
                color: PharmacyColors.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  order.invoiceFileName!,
                  style: PharmacyTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: PharmacyColors.danger,
                ),
                tooltip: 'Remove invoice',
                onPressed: () async {
                  final success = await PharmacyOrdersController.instance
                      .removeOrderInvoice(orderId: order.id);
                  if (!mounted) return;
                  showPortalSnackBar(
                    context,
                    success
                        ? 'Invoice file removed.'
                        : 'Could not remove invoice. Please try again.',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        PharmacySecondaryButton(
          label: order.invoiceFileName == null
              ? 'Upload Bill / Invoice'
              : 'Replace Invoice File',
          compact: true,
          icon: Icons.upload_file_rounded,
          onPressed: () async {
            final file = await pickPrescriptionFile();
            if (file == null) return;
            final success = await PharmacyOrdersController.instance
                .uploadOrderInvoiceFile(
                  orderId: order.id,
                  bytes: file.bytes,
                  fileName: file.name,
                );
            if (!mounted) return;
            showPortalSnackBar(
              context,
              success
                  ? 'Invoice "${file.name}" uploaded successfully.'
                  : 'Could not upload invoice. Please try again.',
            );
          },
        ),
        const SizedBox(height: 8),
        PharmacyPrimaryButton(
          label: 'Send Invoice',
          compact: true,
          icon: Icons.send_rounded,
          onPressed: order.invoiceFileName == null
              ? null
              : () async {
                  final success = await PharmacyOrdersController.instance
                      .sendOrderInvoice(orderId: order.id);
                  if (!mounted) return;
                  showPortalSnackBar(
                    context,
                    success
                        ? 'Invoice sent to customer notification channel.'
                        : 'Could not send invoice. Please try again.',
                  );
                },
        ),
      ],
    ),
  );

  Widget _buildFulfillmentItemTile(
    BuildContext context,
    PharmacyOrderModel order,
    PharmacyOrderItem item,
    bool isUpdating,
  ) {
    final decision = item.decisionStatus.toUpperCase();
    final isRejected = decision == 'REJECTED';
    final isSubstituted = decision == 'SUBSTITUTED';
    final isPartial = decision == 'PARTIAL';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRejected
            ? PharmacyColors.danger.withValues(alpha: 0.04)
            : isSubstituted
            ? Colors.indigo.withValues(alpha: 0.04)
            : isPartial
            ? Colors.orange.withValues(alpha: 0.04)
            : PharmacyColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRejected
              ? PharmacyColors.danger.withValues(alpha: 0.3)
              : isSubstituted
              ? Colors.indigo.withValues(alpha: 0.3)
              : isPartial
              ? Colors.orange.withValues(alpha: 0.3)
              : PharmacyColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: PharmacyTypography.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: isRejected ? TextDecoration.lineThrough : null,
                    color: isRejected
                        ? PharmacyColors.textSecondary
                        : PharmacyColors.text,
                  ),
                ),
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
                style: PharmacyTypography.caption,
              ),
              Text(
                isRejected
                    ? '₹0.00 (Rejected)'
                    : 'Total: ₹${item.lineTotal.toStringAsFixed(2)}',
                style: PharmacyTypography.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isRejected
                      ? PharmacyColors.danger
                      : PharmacyColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // State-specific Decision Banners & Actions
          if (isRejected) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: PharmacyColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cancel_rounded,
                    color: PharmacyColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item Rejected from Fulfillment',
                          style: PharmacyTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: PharmacyColors.danger,
                          ),
                        ),
                        if (item.decisionReason != null &&
                            item.decisionReason!.isNotEmpty)
                          Text(
                            'Reason: ${item.decisionReason}',
                            style: PharmacyTypography.caption.copyWith(
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PharmacySecondaryButton(
                    label: 'Change Decision',
                    compact: true,
                    icon: Icons.refresh_rounded,
                    onPressed: isUpdating
                        ? null
                        : () async {
                            final success = await PharmacyOrdersController
                                .instance
                                .updateOrderItemFulfillment(
                                  orderId: order.id,
                                  itemId: item.id,
                                  fulfillQuantity: item.quantity,
                                  stockStatus: 'FULL_STOCK',
                                  decisionStatus: 'APPROVED',
                                  decisionReason:
                                      'Decision reset by pharmacist.',
                                );
                            if (!context.mounted) return;
                            showPortalSnackBar(
                              context,
                              success
                                  ? '${item.name} decision reset to Approved.'
                                  : 'Could not reset decision: ${PharmacyOrdersController.instance.friendlyError}',
                            );
                          },
                  ),
                ],
              ),
            ),
          ] else if (isSubstituted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.indigo,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Substitute Offered: ${item.substituteName ?? "Alternative Item"}',
                          style: PharmacyTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                      Text(
                        '₹${(item.substituteUnitPrice ?? item.unitPrice).toStringAsFixed(2)} / unit',
                        style: PharmacyTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ],
                  ),
                  if (item.decisionReason != null &&
                      item.decisionReason!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Note: ${item.decisionReason}',
                      style: PharmacyTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PharmacySecondaryButton(
                        label: 'Edit Substitute',
                        compact: true,
                        icon: Icons.edit_outlined,
                        onPressed: isUpdating
                            ? null
                            : () =>
                                  _showSubstituteModal(context, order.id, item),
                      ),
                      const SizedBox(width: 8),
                      PharmacySecondaryButton(
                        label: 'Reset Decision',
                        compact: true,
                        icon: Icons.refresh_rounded,
                        onPressed: isUpdating
                            ? null
                            : () async {
                                final success = await PharmacyOrdersController
                                    .instance
                                    .updateOrderItemFulfillment(
                                      orderId: order.id,
                                      itemId: item.id,
                                      fulfillQuantity: item.quantity,
                                      stockStatus: 'FULL_STOCK',
                                      decisionStatus: 'APPROVED',
                                      decisionReason:
                                          'Substitute cleared by pharmacist.',
                                    );
                                if (!context.mounted) return;
                                showPortalSnackBar(
                                  context,
                                  success
                                      ? 'Substitute cleared for ${item.name}.'
                                      : 'Could not reset decision: ${PharmacyOrdersController.instance.friendlyError}',
                                );
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (isPartial) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.remove_circle_outline,
                    color: Colors.orange.shade900,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partial Quantity Approved: ${item.fulfillQuantity.toStringAsFixed(0)} / ${item.quantity.toStringAsFixed(0)} Units',
                          style: PharmacyTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        if (item.decisionReason != null &&
                            item.decisionReason!.isNotEmpty)
                          Text(
                            'Reason: ${item.decisionReason}',
                            style: PharmacyTypography.caption.copyWith(
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PharmacySecondaryButton(
                    label: 'Change Decision',
                    compact: true,
                    icon: Icons.refresh_rounded,
                    onPressed: isUpdating
                        ? null
                        : () async {
                            final success = await PharmacyOrdersController
                                .instance
                                .updateOrderItemFulfillment(
                                  orderId: order.id,
                                  itemId: item.id,
                                  fulfillQuantity: item.quantity,
                                  stockStatus: 'FULL_STOCK',
                                  decisionStatus: 'APPROVED',
                                  decisionReason:
                                      'Full quantity restored by pharmacist.',
                                );
                            if (!context.mounted) return;
                            showPortalSnackBar(
                              context,
                              success
                                  ? 'Full quantity restored for ${item.name}.'
                                  : 'Could not reset decision: ${PharmacyOrdersController.instance.friendlyError}',
                            );
                          },
                  ),
                ],
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                PharmacySecondaryButton(
                  label: 'Approve Full',
                  compact: true,
                  icon: Icons.check_circle_outline,
                  onPressed: isUpdating
                      ? null
                      : () async {
                          final success = await PharmacyOrdersController
                              .instance
                              .updateOrderItemFulfillment(
                                orderId: order.id,
                                itemId: item.id,
                                fulfillQuantity: item.quantity,
                                stockStatus: 'FULL_STOCK',
                                decisionStatus: 'APPROVED',
                                decisionReason:
                                    'Fully stock approved by pharmacist.',
                              );
                          if (!context.mounted) return;
                          showPortalSnackBar(
                            context,
                            success
                                ? 'Full quantity approved for ${item.name}.'
                                : 'Could not approve item: ${PharmacyOrdersController.instance.friendlyError}',
                          );
                        },
                ),
                if (item.availableQuantity < item.quantity &&
                    item.availableQuantity > 0)
                  PharmacySecondaryButton(
                    label: 'Partial Fulfill',
                    compact: true,
                    icon: Icons.remove_circle_outline,
                    onPressed: isUpdating
                        ? null
                        : () =>
                              _showPartialFulfillModal(context, order.id, item),
                  ),
                PharmacySecondaryButton(
                  label: 'Suggest Substitute',
                  compact: true,
                  icon: Icons.swap_horiz_rounded,
                  onPressed: isUpdating
                      ? null
                      : () => _showSubstituteModal(context, order.id, item),
                ),
                PharmacyDangerButton(
                  label: 'Reject Item',
                  compact: true,
                  icon: Icons.cancel_outlined,
                  onPressed: isUpdating
                      ? null
                      : () async {
                          final success = await PharmacyOrdersController
                              .instance
                              .updateOrderItemFulfillment(
                                orderId: order.id,
                                itemId: item.id,
                                fulfillQuantity: 0,
                                stockStatus: item.stockStatus,
                                decisionStatus: 'REJECTED',
                                decisionReason:
                                    'Item rejected from order fulfillment by pharmacist.',
                              );
                          if (!context.mounted) return;
                          showPortalSnackBar(
                            context,
                            success
                                ? '${item.name} rejected from order fulfillment.'
                                : 'Could not reject item: ${PharmacyOrdersController.instance.friendlyError}',
                          );
                        },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order =
        (PharmacyOrdersController.instance.selectedOrder?.id == widget.order.id
            ? PharmacyOrdersController.instance.selectedOrder
            : null) ??
        widget.order;
    final isUpdating = PharmacyOrdersController.instance.isOrderUpdating(
      order.id,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. FIXED TOP HEADER PANEL
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: PharmacyCard(
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onPopOver != null)
                          IconButton(
                            icon: const Icon(
                              Icons.open_in_full_rounded,
                              size: 20,
                            ),
                            tooltip: 'Expand in Pop-over Modal',
                            onPressed: widget.onPopOver,
                          ),
                        if (widget.onClose != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: widget.onClose,
                          ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildOrderContextFields(context, order),
              ],
            ),
          ),
        ),

        // 2. SCROLLABLE MIDDLE CONTENT AREA (Items List, Notes & Invoices)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PharmacyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Per-Item Fulfillment & Stock Verification',
                            style: PharmacyTypography.subtitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${order.items.length} items',
                            style: PharmacyTypography.caption,
                          ),
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
                          separatorBuilder: (_, __) =>
                              const Divider(height: 20),
                          itemBuilder: (ctx, index) {
                            final item = order.items[index];
                            final isItemUpdating = PharmacyOrdersController
                                .instance
                                .isItemUpdating(order.id, item.id);
                            return _buildFulfillmentItemTile(
                              context,
                              order,
                              item,
                              isItemUpdating,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 600
                      ? Column(
                          children: [
                            _buildNotesCard(order),
                            const SizedBox(height: 16),
                            _buildInvoiceCard(order),
                          ],
                        )
                      : IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildNotesCard(order)),
                              const SizedBox(width: 16),

                              Expanded(child: _buildInvoiceCard(order)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        // 3. FIXED BOTTOM ACTION BAR
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PharmacyCard(
            color: PharmacyColors.surfaceSubtle,
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Payable: ₹ ${order.payableAmount.toStringAsFixed(2)}',
                      style: PharmacyTypography.h3,
                    ),
                    Text(
                      'Payment Status: ${order.paymentStatus}',
                      style: PharmacyTypography.caption,
                    ),
                  ],
                ),
                if (isUpdating)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: PharmacyColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sync_rounded,
                          size: 16,
                          color: PharmacyColors.primary,
                        ),
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
                else if ([
                  'COMPLETED',
                  'DELIVERED',
                  'COLLECTED',
                  'CANCELLED',
                  'REJECTED',
                ].contains(order.status.toUpperCase()))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (order.status == 'CANCELLED' ||
                              order.status == 'REJECTED')
                          ? PharmacyColors.danger.withValues(alpha: 0.1)
                          : PharmacyColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            (order.status == 'CANCELLED' ||
                                order.status == 'REJECTED')
                            ? PharmacyColors.danger.withValues(alpha: 0.3)
                            : PharmacyColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (order.status == 'CANCELLED' ||
                                  order.status == 'REJECTED')
                              ? Icons.cancel_outlined
                              : Icons.check_circle_outline,
                          size: 16,
                          color:
                              (order.status == 'CANCELLED' ||
                                  order.status == 'REJECTED')
                              ? PharmacyColors.danger
                              : PharmacyColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Order Status: ${order.status} (Terminal State)',
                          style: PharmacyTypography.caption.copyWith(
                            color:
                                (order.status == 'CANCELLED' ||
                                    order.status == 'REJECTED')
                                ? PharmacyColors.danger
                                : PharmacyColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (order.status == 'PLACED' ||
                          order.status == 'SUBMITTED' ||
                          order.status == 'NEW')
                        PharmacyPrimaryButton(
                          label: 'Approve Order',
                          icon: Icons.check_circle_rounded,
                          onPressed: () async {
                            final success = await PharmacyOrdersController
                                .instance
                                .updateOrderStatus(
                                  orderId: order.id,
                                  nextStatus: 'ACCEPTED',
                                );
                            if (!context.mounted) return;
                            showPortalSnackBar(
                              context,
                              success
                                  ? 'Order #${order.orderNumber} approved successfully.'
                                  : 'Could not approve order: ${PharmacyOrdersController.instance.friendlyError}',
                            );
                          },
                        ),
                      if (order.status == 'ACCEPTED')
                        PharmacyPrimaryButton(
                          label: 'Start Preparing',
                          icon: Icons.hourglass_top_rounded,
                          onPressed: () async {
                            final success = await PharmacyOrdersController
                                .instance
                                .updateOrderStatus(
                                  orderId: order.id,
                                  nextStatus: 'PREPARING',
                                );
                            if (!context.mounted) return;
                            showPortalSnackBar(
                              context,
                              success
                                  ? 'Order #${order.orderNumber} moved to Preparing.'
                                  : 'Could not update status: ${PharmacyOrdersController.instance.friendlyError}',
                            );
                          },
                        ),
                      if (order.status == 'PREPARING')
                        PharmacyPrimaryButton(
                          label: order.isHomeDelivery
                              ? 'Dispatch Partial/Full'
                              : 'Ready for Pickup',
                          icon: order.isHomeDelivery
                              ? Icons.local_shipping_rounded
                              : Icons.storefront_rounded,
                          onPressed: () async {
                            final next = order.isHomeDelivery
                                ? 'OUT_FOR_DELIVERY'
                                : 'READY_FOR_PICKUP';
                            final success = await PharmacyOrdersController
                                .instance
                                .updateOrderStatus(
                                  orderId: order.id,
                                  nextStatus: next,
                                );
                            if (!context.mounted) return;
                            showPortalSnackBar(
                              context,
                              success
                                  ? 'Order #${order.orderNumber} status updated to $next.'
                                  : 'Could not update status: ${PharmacyOrdersController.instance.friendlyError}',
                            );
                          },
                        ),
                      if (order.status == 'READY_FOR_PICKUP' ||
                          order.status == 'OUT_FOR_DELIVERY')
                        PharmacyPrimaryButton(
                          label: 'Mark Order Completed',
                          icon: Icons.task_alt_rounded,
                          onPressed: () async {
                            final success = await PharmacyOrdersController
                                .instance
                                .updateOrderStatus(
                                  orderId: order.id,
                                  nextStatus: 'COMPLETED',
                                );
                            if (!context.mounted) return;
                            showPortalSnackBar(
                              context,
                              success
                                  ? 'Order #${order.orderNumber} marked as Completed!'
                                  : 'Could not complete order: ${PharmacyOrdersController.instance.friendlyError}',
                            );
                          },
                        ),
                      if (order.status != 'COMPLETED' &&
                          order.status != 'CANCELLED' &&
                          order.status != 'REJECTED')
                        PharmacyDangerButton(
                          label: 'Reject Order',
                          icon: Icons.cancel_outlined,
                          onPressed: () async {
                            final success = await PharmacyOrdersController
                                .instance
                                .updateOrderStatus(
                                  orderId: order.id,
                                  nextStatus: 'CANCELLED',
                                  cancellationReason: 'Rejected by Pharmacy',
                                );
                            if (!context.mounted) return;
                            showPortalSnackBar(
                              context,
                              success
                                  ? 'Order #${order.orderNumber} rejected.'
                                  : 'Could not reject order: ${PharmacyOrdersController.instance.friendlyError}',
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
    );
  }
}
