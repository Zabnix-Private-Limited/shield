import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/utils/app_display_formatters.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../customer/shared/widgets/error_card.dart';
import '../../data/customer_orders_repository.dart';
import '../../domain/customer_order_summary.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key, this.loadOrders, this.repository});

  final Future<List<CustomerOrderSummary>> Function()? loadOrders;
  final CustomerOrdersRepository? repository;

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  late Future<List<CustomerOrderSummary>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture =
        widget.loadOrders?.call() ??
        (widget.repository ?? const CustomerOrdersRepository()).listOrders();
  }

  Future<void> _showOrderDetails(CustomerOrderSummary order) async {
    if (order.id.isEmpty) return;
    try {
      final details =
          await (widget.repository ?? const CustomerOrdersRepository())
              .getOrder(order.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _OrderDetailsSheet(order: details),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order details could not be loaded.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CustomerOrderSummary>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorCard(
            title: 'Orders unavailable',
            message: 'Your pharmacy purchase history could not be loaded.',
            onRetry: () => setState(_loadOrders),
          );
        }
        final orders = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(_loadOrders),
          color: AppColors.shieldBlue,
          child: orders.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [_OrdersEmptyState()],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: orders.length + 1,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) return const _OrdersIntro();
                    return _OrderCard(
                      order: orders[index - 1],
                      onTap: () => _showOrderDetails(orders[index - 1]),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _OrdersIntro extends StatelessWidget {
  const _OrdersIntro();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My orders', style: AppTypography.h3),
        SizedBox(height: 6),
        Text(
          'Completed pharmacy purchases linked to your SHIELD account.',
          style: AppTypography.small,
        ),
      ],
    ),
  );
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 64),
    child: AppCard(
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: AppColors.gray),
          SizedBox(height: 12),
          Text('No orders yet', style: AppTypography.h4),
          SizedBox(height: 6),
          Text(
            'Your pharmacy purchases will appear here after they are recorded.',
            textAlign: TextAlign.center,
            style: AppTypography.small,
          ),
        ],
      ),
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final CustomerOrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus.isEmpty
        ? order.paymentStatus
        : order.orderStatus;
    final amount = order.payableAmount.isEmpty
        ? 'Amount unavailable'
        : AppDisplayFormatters.formatCurrencyString(order.payableAmount);
    return InkWell(
      onTap: order.id.isEmpty ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.providerName.isEmpty
                        ? 'Pharmacy purchase'
                        : order.providerName,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (status.isNotEmpty) _StatusPill(status: status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              amount,
              style: AppTypography.h4.copyWith(color: AppColors.shieldNavy),
            ),
            const SizedBox(height: 5),
            Text(
              [
                if (order.invoiceNumber.isNotEmpty)
                  'Invoice ${order.invoiceNumber}',
                if (order.itemCount > 0)
                  '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                if (order.purchaseDate != null)
                  AppDisplayFormatters.formatDateOrDateTime(
                    order.purchaseDate!.toIso8601String(),
                  ),
              ].join(' • '),
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({required this.order});

  final CustomerOrderDetails order;

  @override
  Widget build(BuildContext context) {
    final amount = order.payableAmount.isEmpty
        ? 'Amount unavailable'
        : AppDisplayFormatters.formatCurrencyString(order.payableAmount);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order details', style: AppTypography.h3),
              const SizedBox(height: 6),
              Text(
                order.invoiceNumber.isEmpty
                    ? 'Recorded pharmacy purchase'
                    : 'Invoice ${order.invoiceNumber}',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 18),
              Text(amount, style: AppTypography.h4),
              const SizedBox(height: 6),
              Text(
                AppDisplayFormatters.formatStatusLabel(order.orderStatus),
                style: AppTypography.small.copyWith(
                  color: AppColors.shieldBlue,
                ),
              ),
              const SizedBox(height: 18),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.name, style: AppTypography.body),
                      ),
                      Text(
                        item.lineTotal.isEmpty
                            ? '—'
                            : AppDisplayFormatters.formatCurrencyString(
                                item.lineTotal,
                              ),
                        style: AppTypography.small.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (order.items.isEmpty)
                Text(
                  'Item details are unavailable for this recorded purchase.',
                  style: AppTypography.small,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.shieldBlue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      AppDisplayFormatters.formatStatusLabel(status),
      style: AppTypography.tiny.copyWith(
        color: AppColors.shieldBlue,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
