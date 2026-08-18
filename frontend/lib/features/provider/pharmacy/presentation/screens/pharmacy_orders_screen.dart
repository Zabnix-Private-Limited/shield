import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_orders_controller.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_order_card.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_order_detail_sheet.dart';
import 'package:shield/shared/widgets/app_skeleton.dart';

class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  State<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen> {
  final PharmacyOrdersController _controller = PharmacyOrdersController.instance;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadOrders();
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

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _controller.setSearchQuery(query);
    });
  }

  void _openOrderDetail(PharmacyOrderModel order) {
    _controller.selectOrder(order);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => PharmacyOrderDetailSheet(
          order: order,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int badgeCount) {
    final isSelected = _controller.activeStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.shieldNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.shieldNavy : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        selectedColor: AppColors.shieldNavy,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.charcoal,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.shieldNavy : Colors.grey.shade300,
          ),
        ),
        onSelected: (_) => _controller.setStatusFilter(value),
      ),
    );
  }

  String? _getPrimaryActionLabel(PharmacyOrderModel order) {
    switch (order.status.toUpperCase()) {
      case 'PLACED':
      case 'SUBMITTED':
      case 'REQUESTED':
      case 'NEW':
        return 'Accept Order';
      case 'ACCEPTED':
        return 'Start Preparing';
      case 'PREPARING':
        return order.isHomeDelivery ? 'Dispatch Delivery' : 'Ready for Pickup';
      case 'READY_FOR_PICKUP':
      case 'OUT_FOR_DELIVERY':
      case 'READY':
        return 'Mark Completed';
      default:
        return null;
    }
  }

  String? _getNextStatus(PharmacyOrderModel order) {
    switch (order.status.toUpperCase()) {
      case 'PLACED':
      case 'SUBMITTED':
      case 'REQUESTED':
      case 'NEW':
        return 'ACCEPTED';
      case 'ACCEPTED':
        return 'PREPARING';
      case 'PREPARING':
        return order.isHomeDelivery ? 'OUT_FOR_DELIVERY' : 'READY_FOR_PICKUP';
      case 'READY_FOR_PICKUP':
      case 'OUT_FOR_DELIVERY':
      case 'READY':
        return 'COMPLETED';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _controller.summary;
    final orders = _controller.orders;
    final isLoading = _controller.isLoading;
    final error = _controller.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Header Surface
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Search TextField
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search order #, customer name or phone...',
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

              // Horizontal Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'ALL', summary?.totalCount ?? 0),
                    _buildFilterChip('New', 'NEW', summary?.newCount ?? 0),
                    _buildFilterChip('Accepted', 'ACCEPTED', summary?.acceptedCount ?? 0),
                    _buildFilterChip('Preparing', 'PREPARING', summary?.preparingCount ?? 0),
                    _buildFilterChip('Ready', 'READY', summary?.readyCount ?? 0),
                    _buildFilterChip('Delivery', 'DELIVERY', summary?.deliveryCount ?? 0),
                    _buildFilterChip('Completed', 'COMPLETED', summary?.completedCount ?? 0),
                    _buildFilterChip('Cancelled', 'CANCELLED', summary?.cancelledCount ?? 0),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Orders Body List
        if (isLoading && orders.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: AppPortalSectionSkeleton(
              showHero: false,
              statCards: 0,
              listItems: 5,
            ),
          ),
        ] else if (error != null && orders.isEmpty) ...[
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
                    'Unable to load pharmacy orders',
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
                    onPressed: () => _controller.loadOrders(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ] else if (orders.isEmpty) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No pharmacy orders found',
                    style: AppTypography.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'No orders match "${_searchController.text}".'
                        : 'New customer orders will appear here for fulfillment.',
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
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final primaryLabel = _getPrimaryActionLabel(order);
              final nextStatus = _getNextStatus(order);

              return PharmacyOrderCard(
                order: order,
                onTap: () => _openOrderDetail(order),
                primaryActionLabel: primaryLabel,
                isActionLoading: _controller.isOrderUpdating(order.id),
                onPrimaryAction: (primaryLabel != null && nextStatus != null)
                    ? () => _controller.updateOrderStatus(
                          orderId: order.id,
                          nextStatus: nextStatus,
                        )
                    : null,
              );
            },
          ),
        ],
      ],
    );
  }
}
