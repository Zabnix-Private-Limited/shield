import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_request_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_payments_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/payment_review_sheet.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_status_chip.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_skeletons.dart';

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

  @override
  Widget build(BuildContext context) {
    final payments = _controller.payments;
    final isLoading = _controller.isLoading;
    final error = _controller.error;
    final activeStatus = _controller.activeStatus;
    final isEmpty = _controller.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Search Card
        PharmacyCard(
          padding: const EdgeInsets.all(16),
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
                        Text(
                          'Manual Payment Verification',
                          style: PharmacyTypography.h2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Review customer bank transfers and UPI receipts. Verification credits customer wallet balance.',
                          style: PharmacyTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: PharmacyColors.navy),
                    tooltip: 'Refresh Payments',
                    onPressed: () => _controller.loadPayments(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Field
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search customer name, phone, code or UTR reference...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: PharmacyColors.textSecondary),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['ALL', 'PENDING', 'APPROVED', 'REJECTED'].map((st) {
                    final isSel = activeStatus == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(st),
                        selected: isSel,
                        selectedColor: PharmacyColors.primarySoft,
                        labelStyle: PharmacyTypography.caption.copyWith(
                          color: isSel
                              ? PharmacyColors.primaryHover
                              : PharmacyColors.text,
                          fontWeight:
                              isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: PharmacyColors.canvas,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(PharmacyRadius.chip),
                          side: BorderSide(
                            color: isSel
                                ? PharmacyColors.primary
                                : PharmacyColors.border,
                          ),
                        ),
                        onSelected: (_) => _controller.setActiveStatus(st),
                      ),
                    );
                  }).toList(),
                ),
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
                  const Icon(Icons.error_outline_rounded,
                      size: 44, color: PharmacyColors.danger),
                  const SizedBox(height: 10),
                  Text('Unable to load payment requests',
                      style: PharmacyTypography.subtitle
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(error, style: PharmacyTypography.caption),
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
                                    style: PharmacyTypography.subtitle
                                        .copyWith(fontWeight: FontWeight.bold),
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
                              Text('Payment Amount',
                                  style: PharmacyTypography.tiny),
                              Text(
                                '₹ ${p.amount.toStringAsFixed(2)}',
                                style: PharmacyTypography.h3,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Payment Channel',
                                  style: PharmacyTypography.tiny),
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
                            label: p.isPending ? 'Review & Verify' : 'View Details',
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
}
