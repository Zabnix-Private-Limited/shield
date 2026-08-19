import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_request_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_payments_controller.dart';

class PaymentReviewSheet extends StatefulWidget {
  final PharmacyPaymentRequestModel payment;
  final VoidCallback onUpdated;

  const PaymentReviewSheet({
    super.key,
    required this.payment,
    required this.onUpdated,
  });

  @override
  State<PaymentReviewSheet> createState() => _PaymentReviewSheetState();
}

class _PaymentReviewSheetState extends State<PaymentReviewSheet> {
  final PharmacyPaymentsController _controller =
      PharmacyPaymentsController.instance;

  bool _isActionRunning = false;

  Future<void> _confirmApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment Approval'),
        content: Text(
          'Approve ₹${widget.payment.amount.toStringAsFixed(2)} cash wallet credit for ${widget.payment.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.shieldGreen,
            ),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isActionRunning = true);
      final success = await _controller.approvePayment(widget.payment.id);
      if (mounted) {
        setState(() => _isActionRunning = false);
        if (success) {
          widget.onUpdated();
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _promptReject() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmedReason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Payment Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejecting this payment:'),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'e.g. Reference number not found in bank statement',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Rejection reason is required'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmedReason != null && confirmedReason.isNotEmpty && mounted) {
      setState(() => _isActionRunning = true);
      final success = await _controller.rejectPayment(
        widget.payment.id,
        confirmedReason,
      );
      if (mounted) {
        setState(() => _isActionRunning = false);
        if (success) {
          widget.onUpdated();
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final dest = p.destinationSnapshot;

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
                Text(
                  'Payment Review',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.shieldNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.shieldLightBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.shieldBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Claimed Payment Amount',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.shieldNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ ${p.amount.toStringAsFixed(2)}',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.shieldNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer Info
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
              title: Text(p.customerName, style: AppTypography.subtitle2),
              subtitle: Text(
                'Code: ${p.customerCode.isNotEmpty ? p.customerCode : 'N/A'} • Mobile: ${p.customerPhone}',
                style: AppTypography.caption,
              ),
            ),
            const Divider(height: 20),

            // Details Grid
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Channel', style: AppTypography.caption),
                      const SizedBox(height: 2),
                      Chip(
                        label: Text(
                          p.paymentChannel.replaceAll('_', ' '),
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.shieldNavy,
                          ),
                        ),
                        backgroundColor: AppColors.shieldLightBlue.withValues(alpha: 0.2),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: AppTypography.caption),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.isApproved
                              ? AppColors.mintGreen
                              : p.isRejected
                                  ? Colors.red.shade100
                                  : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          p.status,
                          style: AppTypography.caption.copyWith(
                            color: p.isApproved
                                ? AppColors.shieldGreen
                                : p.isRejected
                                    ? Colors.red.shade800
                                    : Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text('Reference / UTR Number', style: AppTypography.caption),
            const SizedBox(height: 2),
            SelectableText(
              p.referenceNumber.isNotEmpty ? p.referenceNumber : 'None Provided',
              style: AppTypography.subtitle2.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Destination Snapshot
            if (dest != null) ...[
              Text('Payment Destination Used', style: AppTypography.caption),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dest['methodType'] == 'BANK_ACCOUNT'
                          ? '${dest['bankName'] ?? 'Bank'} (${dest['accountNumber'] ?? ''})'
                          : 'UPI: ${dest['upiId'] ?? ''}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (dest['accountHolderName'] != null)
                      Text(
                        'Holder: ${dest['accountHolderName']}',
                        style: AppTypography.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Rejection Reason
            if (p.isRejected && p.rejectionReason != null) ...[
              Text('Rejection Reason', style: AppTypography.caption),
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
                  p.rejectionReason!,
                  style: AppTypography.caption.copyWith(
                    color: Colors.red.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Proof Image Preview
            if (p.proofUrl != null) ...[
              Text('Payment Proof Image', style: AppTypography.caption),
              const SizedBox(height: 6),
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    p.proofUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined, size: 36),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (p.isPending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isActionRunning ? null : _promptReject,
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject Payment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isActionRunning ? null : _confirmApprove,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Approve & Credit',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.shieldGreen,
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
