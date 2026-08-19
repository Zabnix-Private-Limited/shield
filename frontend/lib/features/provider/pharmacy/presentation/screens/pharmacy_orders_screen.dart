import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_radius.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_orders_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_status_chip.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_fulfillment_detail_view.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_skeletons.dart';

class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  State<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen> {
  final PharmacyOrdersController _controller =
      PharmacyOrdersController.instance;
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
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _controller.setSearchQuery(query);
    });
  }

  void _openMobileOrderDetail(PharmacyOrderModel order) {
    _controller.selectOrder(order);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: PharmacyColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: PharmacyFulfillmentDetailView(
            order: order,
            onClose: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _controller.activeStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PharmacyColors.primary
                      : PharmacyColors.navy,
                  borderRadius: BorderRadius.circular(PharmacyRadius.chip),
                ),
                child: Text(
                  '$count',
                  style: PharmacyTypography.tiny.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        selectedColor: PharmacyColors.primarySoft,
        labelStyle: PharmacyTypography.caption.copyWith(
          color: isSelected
              ? PharmacyColors.primaryHover
              : PharmacyColors.text,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: PharmacyColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmacyRadius.chip),
          side: BorderSide(
            color: isSelected
                ? PharmacyColors.primary
                : PharmacyColors.border,
          ),
        ),
        onSelected: (_) => _controller.setStatusFilter(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _controller.summary;
    final orders = _controller.orders;
    final isLoading = _controller.isLoading;
    final error = _controller.error;
    final selectedOrder = _controller.selectedOrder ??
        (orders.isNotEmpty ? orders.first : null);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Search & Filter Bar
        PharmacyCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText:
                            'Search order #, customer name, phone, or items...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: PharmacyColors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _controller.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        filled: true,
                        fillColor: PharmacyColors.canvas,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(PharmacyRadius.field),
                          borderSide:
                              const BorderSide(color: PharmacyColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: PharmacyColors.navy),
                    tooltip: 'Refresh Orders Queue',
                    onPressed: () => _controller.loadOrders(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Queue Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Orders', 'ALL', summary?.totalCount ?? 0),
                    _buildFilterChip('New', 'NEW', summary?.newCount ?? 0),
                    _buildFilterChip('Accepted', 'ACCEPTED', summary?.acceptedCount ?? 0),
                    _buildFilterChip('Preparing', 'PREPARING', summary?.preparingCount ?? 0),
                    _buildFilterChip('Ready for Pickup', 'READY_FOR_PICKUP', summary?.readyCount ?? 0),
                    _buildFilterChip('Out for Delivery', 'OUT_FOR_DELIVERY', summary?.deliveryCount ?? 0),
                    _buildFilterChip('Chronic Orders', 'CHRONIC', summary?.chronicCount ?? 0),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (isLoading && orders.isEmpty) ...[
          const PharmacyOrdersSkeleton(),
        ] else if (error != null && orders.isEmpty) ...[
          PharmacyCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 44, color: PharmacyColors.danger),
                  const SizedBox(height: 10),
                  Text('Unable to load orders queue',
                      style: PharmacyTypography.subtitle
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(error, style: PharmacyTypography.caption),
                  const SizedBox(height: 14),
                  PharmacyPrimaryButton(
                    label: 'Retry',
                    onPressed: () => _controller.loadOrders(),
                  ),
                ],
              ),
            ),
          ),
        ] else if (orders.isEmpty) ...[
          const PharmacyEmptyState(
            title: 'No orders found',
            subtitle:
                'No orders match the selected filter or search query.',
            icon: Icons.assignment_outlined,
          ),
        ] else ...[
          // Split Pane for Desktop / Stacked for Mobile
          isDesktop
              ? SizedBox(
                  height: 720,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Queue List Column
                      SizedBox(
                        width: 380,
                        child: ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (ctx, index) {
                            final order = orders[index];
                            final isSelected = selectedOrder?.id == order.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: PharmacyCard(
                                padding: const EdgeInsets.all(12),
                                border: Border.all(
                                  color: isSelected
                                      ? PharmacyColors.primary
                                      : PharmacyColors.border,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                child: InkWell(
                                  onTap: () =>
                                      _controller.selectOrder(order),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            order.orderNumber,
                                            style: PharmacyTypography.subtitle
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          PharmacyStatusChip(
                                              status: order.status, compact: true),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        order.customer?.fullName ??
                                            'Walk-in Customer',
                                        style: PharmacyTypography.caption
                                            .copyWith(
                                                color: PharmacyColors.text),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${order.items.length} items • ${order.displayFulfillment}',
                                            style: PharmacyTypography.tiny,
                                          ),
                                          Text(
                                            '₹ ${order.payableAmount.toStringAsFixed(2)}',
                                            style: PharmacyTypography.caption
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: PharmacyColors
                                                        .navy),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Right Selected Order Detail Workspace
                      Expanded(
                        child: selectedOrder != null
                            ? PharmacyFulfillmentDetailView(
                                order: selectedOrder,
                              )
                            : const PharmacyEmptyState(
                                title: 'Select an order',
                                subtitle:
                                    'Click an order on the left to view fulfillment details.',
                              ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (ctx, index) {
                    final order = orders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PharmacyCard(
                        padding: const EdgeInsets.all(14),
                        child: InkWell(
                          onTap: () => _openMobileOrderDetail(order),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.orderNumber,
                                    style: PharmacyTypography.subtitle
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  PharmacyStatusChip(status: order.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                order.customer?.fullName ??
                                    'Walk-in Customer',
                                style: PharmacyTypography.caption
                                    .copyWith(color: PharmacyColors.text),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${order.items.length} items • ${order.displayFulfillment}',
                                    style: PharmacyTypography.tiny,
                                  ),
                                  Text(
                                    '₹ ${order.payableAmount.toStringAsFixed(2)}',
                                    style: PharmacyTypography.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: PharmacyColors.navy),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
