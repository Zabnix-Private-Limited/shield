import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_order_history_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_order_history_card.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_order_history_detail_sheet.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_skeletons.dart';
import 'package:shield/features/provider/pharmacy/presentation/pharmacy_error_message.dart';

class PharmacyOrderHistoryScreen extends StatefulWidget {
  const PharmacyOrderHistoryScreen({super.key});

  @override
  State<PharmacyOrderHistoryScreen> createState() =>
      _PharmacyOrderHistoryScreenState();
}

class _PharmacyOrderHistoryScreenState
    extends State<PharmacyOrderHistoryScreen> {
  final PharmacyOrderHistoryController _controller =
      PharmacyOrderHistoryController.instance;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadHistory();
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

  void _openDetailSheet(PharmacyOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PharmacyOrderHistoryDetailSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _controller.orders;
    final summary = _controller.summary;
    final isLoading = _controller.isLoading;
    final isLoadingMore = _controller.isLoadingMore;
    final error = _controller.error;
    final activeStatus = _controller.activeStatus;
    final activeDatePreset = _controller.activeDatePreset;
    final isEmpty = _controller.isEmpty;
    final hasMore = _controller.hasMore;

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
                        Text('Order History Log', style: PharmacyTypography.h2),
                        const SizedBox(height: 4),
                        Text(
                          'Terminal historical records of completed, cancelled, and rejected pharmacy orders.',
                          style: PharmacyTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: PharmacyColors.navy,
                    ),
                    tooltip: 'Refresh Order History',
                    onPressed: () => _controller.loadHistory(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Field
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search order #, customer name, mobile or code...',
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
                children: ['ALL_HISTORY', 'COMPLETED', 'CANCELLED', 'REJECTED']
                    .map((st) {
                      final isSel = activeStatus == st;
                      final label = st == 'ALL_HISTORY'
                          ? 'All History'
                          : st.replaceAll('_', ' ');
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSel,
                        selectedColor: PharmacyColors.primarySoft,
                        labelStyle: PharmacyTypography.caption.copyWith(
                          color: isSel
                              ? PharmacyColors.primaryHover
                              : PharmacyColors.text,
                          fontWeight: isSel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: PharmacyColors.canvas,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            PharmacyRadius.chip,
                          ),
                          side: BorderSide(
                            color: isSel
                                ? PharmacyColors.primary
                                : PharmacyColors.border,
                          ),
                        ),
                        onSelected: (_) => _controller.setActiveStatus(st),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Date Preset Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'ALL_TIME',
                      'TODAY',
                      'LAST_7_DAYS',
                      'LAST_30_DAYS',
                      'THIS_MONTH',
                    ].map((dt) {
                      final isSel = activeDatePreset == dt;
                      final label = dt == 'ALL_TIME'
                          ? 'All Time'
                          : dt.replaceAll('_', ' ');
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSel,
                        selectedColor: PharmacyColors.navy,
                        labelStyle: PharmacyTypography.tiny.copyWith(
                          color: isSel ? Colors.white : PharmacyColors.text,
                        ),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => _controller.setActiveDatePreset(dt),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Metrics Summary Banner
        if (summary != null) ...[
          PharmacyCard(
            color: PharmacyColors.primarySoft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Total Order Value', style: PharmacyTypography.tiny),
                    Text(
                      '₹ ${summary.completedOrderValue.toStringAsFixed(2)}',
                      style: PharmacyTypography.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: PharmacyColors.borderStrong,
                ),
                Column(
                  children: [
                    Text('Completed Orders', style: PharmacyTypography.tiny),
                    Text(
                      '${summary.totalCompletedCount}',
                      style: PharmacyTypography.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: PharmacyColors.primaryHover,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: PharmacyColors.borderStrong,
                ),
                Column(
                  children: [
                    Text(
                      'Cancelled / Rejected',
                      style: PharmacyTypography.tiny,
                    ),
                    Text(
                      '${summary.totalCancelledCount + summary.totalRejectedCount}',
                      style: PharmacyTypography.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: PharmacyColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // History Records List
        if (isLoading && isEmpty) ...[
          const PharmacyOrderHistorySkeleton(),
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
                    'Unable to load order history',
                    style: PharmacyTypography.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pharmacyFriendlyErrorMessage(
                      error,
                      fallback:
                          "Order history couldn't be loaded. Please try again.",
                    ),
                    style: PharmacyTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  PharmacyPrimaryButton(
                    label: 'Retry Loading',
                    onPressed: () => _controller.loadHistory(),
                  ),
                ],
              ),
            ),
          ),
        ] else if (isEmpty) ...[
          const PharmacyEmptyState(
            title: 'No historical records found',
            subtitle:
                'Completed and cancelled orders will appear here for audit and reporting.',
            icon: Icons.history_rounded,
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == orders.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: isLoadingMore
                        ? const Column(
                            children: [
                              PharmacySkeletonBlock(height: 72),
                              SizedBox(height: 8),
                              PharmacySkeletonBlock(height: 72),
                            ],
                          )
                        : PharmacySecondaryButton(
                            label: 'Load More Records',
                            icon: Icons.arrow_downward_rounded,
                            onPressed: () => _controller.loadMore(),
                          ),
                  ),
                );
              }

              final order = orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PharmacyOrderHistoryCard(
                  order: order,
                  onTapDetail: () => _openDetailSheet(order),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
