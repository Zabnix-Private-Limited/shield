import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/shared/widgets/app_skeleton.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_order_history_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_order_history_card.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_order_history_detail_sheet.dart';

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
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Controls & Header Container
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order History',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.shieldNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Terminal records of completed, cancelled, and rejected pharmacy orders.',
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
                  hintText: 'Search order #, customer name, mobile or code...',
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
              const SizedBox(height: 10),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'ALL_HISTORY',
                    'COMPLETED',
                    'CANCELLED',
                    'REJECTED',
                  ].map((st) {
                    final isSel = activeStatus == st;
                    final label = st == 'ALL_HISTORY'
                        ? 'All History'
                        : st.replaceAll('_', ' ');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSel,
                        selectedColor: AppColors.shieldNavy,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.charcoal,
                          fontWeight:
                              isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => _controller.setActiveStatus(st),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),

              // Date Preset Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
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
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSel,
                        selectedColor: AppColors.shieldBlue,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : Colors.grey.shade700,
                          fontSize: 11,
                        ),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => _controller.setActiveDatePreset(dt),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // History Summary KPI Strip
        if (summary != null) ...[
          Container(
            color: AppColors.shieldLightBlue.withValues(alpha: 0.12),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Order Value',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '₹ ${summary.completedOrderValue.toStringAsFixed(2)}',
                      style: AppTypography.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldNavy,
                      ),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      'Completed',
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                    Text(
                      '${summary.totalCompletedCount}',
                      style: AppTypography.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.shieldGreen,
                      ),
                    ),
                  ],
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      'Cancelled / Rejected',
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                    Text(
                      '${summary.totalCancelledCount + summary.totalRejectedCount}',
                      style: AppTypography.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        // History List Content
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
                    'Unable to load order history',
                    style: AppTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please retry. If the problem continues, contact support.',
                    style: AppTypography.body2.copyWith(color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: AppTypography.caption.copyWith(color: Colors.red.shade700, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _controller.loadHistory(),
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
                    Icons.history_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No completed or cancelled orders yet',
                    style: AppTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Terminal orders will appear here once fulfilled or cancelled.',
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
            itemCount: orders.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == orders.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: isLoadingMore
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _controller.loadMore(),
                            icon: const Icon(Icons.arrow_downward, size: 16),
                            label: const Text('Load More Records'),
                          ),
                  ),
                );
              }

              final order = orders[index];
              return PharmacyOrderHistoryCard(
                order: order,
                onTapDetail: () => _openDetailSheet(order),
              );
            },
          ),
        ],
      ],
    );
  }
}
