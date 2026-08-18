import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/shared/widgets/app_skeleton.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_request_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_payments_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/payment_review_sheet.dart';

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
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Controls & Header Surface
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manual Payment Verification',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.shieldNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Verify and approve customer bank transfers and UPI payment receipts.',
                style: AppTypography.caption.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              // Search Field
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search customer name, phone, code or UTR reference...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _controller.setSearchQuery('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
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
                        selectedColor: AppColors.shieldNavy,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.charcoal,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
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
        const Divider(height: 1),

        // Payments List Content
        if (isLoading && isEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: AppPortalSectionSkeleton(
              showHero: false,
              statCards: 0,
              listItems: 5,
            ),
          ),
        ] else if (error != null && isEmpty) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load payment requests',
                    style: AppTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error,
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _controller.loadPayments(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ] else if (isEmpty) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No payment requests found',
                    style: AppTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payment submissions from customers will appear here for review.',
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ListView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final p = payments[index];
              return _buildPaymentCard(p);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentCard(PharmacyPaymentRequestModel p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: p.isPending ? AppColors.shieldBlue : Colors.grey.shade200,
          width: p.isPending ? 1.5 : 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.shieldLightBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        size: 20,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.customerName,
                          style: AppTypography.subtitle2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.shieldNavy,
                          ),
                        ),
                        Text(
                          'Ref: ${p.referenceNumber.isNotEmpty ? p.referenceNumber : 'N/A'}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount', style: AppTypography.caption),
                    Text(
                      '₹ ${p.amount.toStringAsFixed(2)}',
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
                    Text('Channel', style: AppTypography.caption),
                    Text(
                      p.paymentChannel.replaceAll('_', ' '),
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
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
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openReviewSheet(p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        p.isPending ? AppColors.shieldNavy : Colors.grey.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.rate_review_outlined,
                      size: 14, color: Colors.white),
                  label: Text(
                    p.isPending ? 'Review & Verify' : 'View Details',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
