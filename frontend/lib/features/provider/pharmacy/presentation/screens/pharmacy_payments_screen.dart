import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_request_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_payments_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/counter_payment_dialog.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/payment_review_sheet.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_status_chip.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_skeletons.dart';
import 'package:shield/features/provider/pharmacy/presentation/pharmacy_error_message.dart';

class PharmacyPaymentsScreen extends StatefulWidget {
  const PharmacyPaymentsScreen({super.key});

  @override
  State<PharmacyPaymentsScreen> createState() => _PharmacyPaymentsScreenState();
}

class _PharmacyPaymentsScreenState extends State<PharmacyPaymentsScreen> {
  final PharmacyPaymentsController _controller =
      PharmacyPaymentsController.instance;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadPayments();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _controller.setSearchQuery(val);
    });
  }

  void _openReviewSheet(PharmacyPaymentRequestModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentReviewSheet(
        payment: p,
        onUpdated: () => _controller.loadPayments(quiet: true),
      ),
    );
  }

  void _openCounterPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CounterPaymentDialog(
        onSaved: () => _controller.loadPayments(quiet: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payments = _controller.payments;
    final isLoading = _controller.isLoading;
    final error = _controller.error;
    final activeStatus = _controller.activeStatus;
    final isEmpty = _controller.isEmpty;

    final pendingCount = payments.where((p) => p.isPending).length;
    final approvedCount = payments.where((p) => p.isApproved).length;

    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Search Card
        PharmacyCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPhone) ...[
                Text(
                  'Payment Verification & Counter Acceptance',
                  style: PharmacyTypography.h2.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review customer bank transfers and UPI receipts, or record walk-in counter payments in real time.',
                  style: PharmacyTypography.caption,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PharmacyPrimaryButton(
                        label: '+ Accept Counter Payment',
                        icon: Icons.point_of_sale_rounded,
                        onPressed: _openCounterPaymentDialog,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: PharmacyColors.navy,
                      ),
                      tooltip: 'Refresh Payments',
                      onPressed: () => _controller.loadPayments(),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Verification & Counter Acceptance',
                            style: PharmacyTypography.h2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Review customer bank transfers and UPI receipts, or record walk-in counter payments in real time.',
                            style: PharmacyTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        PharmacyPrimaryButton(
                          label: '+ Accept Counter Payment',
                          icon: Icons.point_of_sale_rounded,
                          onPressed: _openCounterPaymentDialog,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: PharmacyColors.navy,
                          ),
                          tooltip: 'Refresh Payments',
                          onPressed: () => _controller.loadPayments(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),

              // Payment Summary Cards Banner
              if (isPhone)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSummaryCard(
                      icon: Icons.pending_actions_rounded,
                      color: PharmacyColors.warning,
                      label: 'Pending Verification',
                      value: '$pendingCount Payments',
                    ),
                    _buildSummaryCard(
                      icon: Icons.verified_rounded,
                      color: PharmacyColors.primary,
                      label: 'Verified & Approved',
                      value: '$approvedCount Payments',
                    ),
                    _buildSummaryCard(
                      icon: Icons.point_of_sale_rounded,
                      color: PharmacyColors.navy,
                      label: 'Counter Receipts',
                      value: 'Walk-in Active',
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: PharmacyColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PharmacyColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pending_actions_rounded,
                            color: PharmacyColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Verification',
                                style: PharmacyTypography.tiny,
                              ),
                              Text(
                                '$pendingCount Payments',
                                style: PharmacyTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PharmacyColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: PharmacyColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PharmacyColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: PharmacyColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified & Approved',
                                style: PharmacyTypography.tiny,
                              ),
                              Text(
                                '$approvedCount Payments',
                                style: PharmacyTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PharmacyColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: PharmacyColors.canvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PharmacyColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.point_of_sale_rounded,
                            color: PharmacyColors.navy,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Counter Receipts',
                                style: PharmacyTypography.tiny,
                              ),
                              Text(
                                'Walk-in Active',
                                style: PharmacyTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PharmacyColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),

              // Search Field
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText:
                      'Search customer name, phone, code or UTR reference...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: PharmacyColors.textSecondary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _controller.setSearchQuery('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: PharmacyColors.canvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PharmacyRadius.field),
                    borderSide: const BorderSide(color: PharmacyColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status Filter Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['ALL', 'PENDING', 'APPROVED', 'REJECTED'].map((st) {
                  final isSel = activeStatus == st;
                  return ChoiceChip(
                    label: Text(st),
                    selected: isSel,
                    selectedColor: PharmacyColors.primarySoft,
                    labelStyle: PharmacyTypography.caption.copyWith(
                      color: isSel
                          ? PharmacyColors.primaryHover
                          : PharmacyColors.text,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: PharmacyColors.canvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PharmacyRadius.chip),
                      side: BorderSide(
                        color: isSel
                            ? PharmacyColors.primary
                            : PharmacyColors.border,
                      ),
                    ),
                    onSelected: (_) => _controller.setActiveStatus(st),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List Content
        if (isLoading && isEmpty) ...[
          const PharmacyPaymentsSkeleton(),
        ] else if (error != null && isEmpty) ...[
          PharmacyCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: PharmacyColors.danger,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Unable to load payment requests',
                    style: PharmacyTypography.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pharmacyFriendlyErrorMessage(
                      error,
                      fallback:
                          "Payments couldn't be loaded. Please try again.",
                    ),
                    style: PharmacyTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  PharmacyPrimaryButton(
                    label: 'Retry Loading',
                    onPressed: () => _controller.loadPayments(),
                  ),
                ],
              ),
            ),
          ),
        ] else if (isEmpty) ...[
          const PharmacyEmptyState(
            title: 'No payment verification requests found',
            subtitle:
                'Customer submitted bank transfers and UPI payment proofs will appear here.',
            icon: Icons.payments_outlined,
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final p = payments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PharmacyCard(
                  border: Border.all(
                    color: p.isPending
                        ? PharmacyColors.warning
                        : PharmacyColors.border,
                    width: p.isPending ? 1.5 : 1.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: PharmacyColors.primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 20,
                                  color: PharmacyColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.customerName,
                                    style: PharmacyTypography.subtitle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Ref/UTR: ${p.referenceNumber.isNotEmpty ? p.referenceNumber : 'N/A'}',
                                    style: PharmacyTypography.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          PharmacyStatusChip(status: p.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Amount',
                                style: PharmacyTypography.tiny,
                              ),
                              Text(
                                '₹ ${p.amount.toStringAsFixed(2)}',
                                style: PharmacyTypography.h3,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Payment Channel',
                                style: PharmacyTypography.tiny,
                              ),
                              Text(
                                p.paymentChannel.replaceAll('_', ' '),
                                style: PharmacyTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PharmacyColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p.createdAt != null
                                ? 'Submitted: ${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}'
                                : '',
                            style: PharmacyTypography.caption,
                          ),
                          PharmacyPrimaryButton(
                            label: p.isPending
                                ? 'Review & Verify'
                                : 'View Details',
                            compact: true,
                            icon: Icons.rate_review_outlined,
                            onPressed: () => _openReviewSheet(p),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: PharmacyTypography.tiny,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: PharmacyTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: PharmacyColors.navy,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
