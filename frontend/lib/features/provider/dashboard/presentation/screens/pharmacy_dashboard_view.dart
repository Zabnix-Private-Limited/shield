import 'package:flutter/material.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_colors.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_spacing.dart';
import 'package:shield/features/provider/pharmacy/design/pharmacy_typography.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_dashboard_controller.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_components.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_metric_card.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_status_chip.dart';

class PharmacyDashboardView extends StatefulWidget {
  final Function(String sectionKey)? onNavigateToSection;

  const PharmacyDashboardView({
    super.key,
    this.onNavigateToSection,
  });

  @override
  State<PharmacyDashboardView> createState() => _PharmacyDashboardViewState();
}

class _PharmacyDashboardViewState extends State<PharmacyDashboardView> {
  final PharmacyDashboardController _controller =
      PharmacyDashboardController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadDashboard();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _controller.isLoading;
    final error = _controller.error;
    final data = _controller.dashboardData;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Operations Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pharmacy Operations Center',
                    style: PharmacyTypography.h2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time order fulfillment, stock workflow management, and payment verification.',
                    style: PharmacyTypography.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: PharmacyColors.navy),
              tooltip: 'Refresh Dashboard Data',
              onPressed: () => _controller.loadDashboard(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (isLoading && data == null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: PharmacyColors.primary),
            ),
          ),
        ] else if (error != null && data == null) ...[
          PharmacyCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: PharmacyColors.danger,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unable to load Pharmacy Operations',
                  style: PharmacyTypography.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  error,
                  style: PharmacyTypography.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PharmacyPrimaryButton(
                  label: 'Retry Loading',
                  icon: Icons.refresh_rounded,
                  onPressed: () => _controller.loadDashboard(),
                ),
              ],
            ),
          ),
        ] else if (data != null) ...[
          // Payment Configuration Action Alert
          if (!data.paymentConfiguration.bankConfigured ||
              !data.paymentConfiguration.upiConfigured) ...[
            PharmacyAlertBanner(
              title: 'Action Required: Configure Bank & UPI Details',
              message:
                  'Customer manual payment submissions require active Bank Account and UPI QR configuration.',
              actionLabel: 'Configure Now',
              onAction: () =>
                  widget.onNavigateToSection?.call('payment-details'),
            ),
          ],

          // Operational KPI Grid (Orders)
          Text(
            'Order Operations Overview',
            style: PharmacyTypography.subtitle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              PharmacyMetricCard(
                title: 'New Orders',
                value: '${data.orders.newCount}',
                icon: Icons.shopping_bag_outlined,
                iconColor: PharmacyColors.info,
                badge: 'Pending',
                badgeColor: PharmacyColors.info,
                onTap: () => widget.onNavigateToSection?.call('orders'),
              ),
              PharmacyMetricCard(
                title: 'Preparing',
                value: '${data.orders.preparingCount}',
                icon: Icons.hourglass_top_outlined,
                iconColor: PharmacyColors.warning,
                badge: 'In Progress',
                badgeColor: PharmacyColors.warning,
                onTap: () => widget.onNavigateToSection?.call('orders'),
              ),
              PharmacyMetricCard(
                title: 'Ready for Pickup',
                value: '${data.orders.readyCount}',
                icon: Icons.check_circle_outline,
                iconColor: PharmacyColors.primary,
                badge: 'Store Pickup',
                badgeColor: PharmacyColors.primary,
                onTap: () => widget.onNavigateToSection?.call('orders'),
              ),
              PharmacyMetricCard(
                title: 'Out for Delivery',
                value: '${data.orders.deliveryCount}',
                icon: Icons.local_shipping_outlined,
                iconColor: PharmacyColors.purple,
                badge: 'In Transit',
                badgeColor: PharmacyColors.purple,
                onTap: () => widget.onNavigateToSection?.call('orders'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Financial & Verification Metrics Grid
          Text(
            'Financial & Verification Summary',
            style: PharmacyTypography.subtitle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              PharmacyMetricCard(
                title: 'Pending Payments',
                value: '${data.payments.pendingVerification}',
                icon: Icons.pending_actions_outlined,
                iconColor: PharmacyColors.warning,
                badge: 'Verification Needed',
                badgeColor: PharmacyColors.warning,
                onTap: () => widget.onNavigateToSection?.call('payments'),
              ),
              PharmacyMetricCard(
                title: 'Approved Today',
                value: '${data.payments.approvedToday}',
                icon: Icons.verified_outlined,
                iconColor: PharmacyColors.primary,
                subtitle:
                    '₹ ${data.payments.approvedAmountToday.toStringAsFixed(2)}',
                onTap: () => widget.onNavigateToSection?.call('payments'),
              ),
              PharmacyMetricCard(
                title: 'Completed Today',
                value: '${data.orders.completedToday}',
                icon: Icons.task_alt_rounded,
                iconColor: PharmacyColors.navy,
                subtitle:
                    '₹ ${data.orders.orderValueToday.toStringAsFixed(2)}',
                onTap: () => widget.onNavigateToSection?.call('history'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Recent Orders Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders Queue',
                style: PharmacyTypography.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => widget.onNavigateToSection?.call('orders'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View All Orders'),
                style: TextButton.styleFrom(
                  foregroundColor: PharmacyColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (data.recentOrders.isEmpty) ...[
            const PharmacyEmptyState(
              title: 'No recent orders in queue',
              subtitle: 'New orders will appear here as customers place them.',
              icon: Icons.shopping_bag_outlined,
            ),
          ] else ...[
            ...data.recentOrders.map(
              (o) => PharmacyCard(
                padding: const EdgeInsets.all(12),
                child: InkWell(
                  onTap: () => widget.onNavigateToSection?.call('orders'),
                  borderRadius: BorderRadius.circular(PharmacyRadius.card),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PharmacyColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: PharmacyColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${o.invoiceNumber} • ${o.customerName}',
                              style: PharmacyTypography.subtitle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Payable: ₹ ${o.payableAmount.toStringAsFixed(2)}',
                              style: PharmacyTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      PharmacyStatusChip(status: o.orderStatus),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: PharmacyColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),

          // Recent Payments Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Payment Requests',
                style: PharmacyTypography.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => widget.onNavigateToSection?.call('payments'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('View All Payments'),
                style: TextButton.styleFrom(
                  foregroundColor: PharmacyColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (data.recentPayments.isEmpty) ...[
            const PharmacyEmptyState(
              title: 'No recent payment verification requests',
              subtitle: 'Submitted manual payment receipts will appear here.',
              icon: Icons.payments_outlined,
            ),
          ] else ...[
            ...data.recentPayments.map(
              (p) => PharmacyCard(
                padding: const EdgeInsets.all(12),
                child: InkWell(
                  onTap: () => widget.onNavigateToSection?.call('payments'),
                  borderRadius: BorderRadius.circular(PharmacyRadius.card),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PharmacyColors.warningBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: PharmacyColors.warningText,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${p.customerName} (${p.customerCode.isNotEmpty ? p.customerCode : 'Customer'})',
                              style: PharmacyTypography.subtitle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹ ${p.amount.toStringAsFixed(2)} via ${p.paymentChannel.replaceAll('_', ' ')}',
                              style: PharmacyTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      PharmacyStatusChip(status: p.status),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: PharmacyColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
