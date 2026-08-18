import 'package:flutter/material.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/app/theme/app_typography.dart';
import 'package:shield/shared/widgets/app_skeleton.dart';
import 'package:shield/features/provider/pharmacy/presentation/controllers/pharmacy_dashboard_controller.dart';

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
        // Header Row with Title, Subtitle, and Refresh Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pharmacy Operations Dashboard',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.shieldNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live operational metrics, order fulfillment queue, and manual payment verification.',
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.shieldNavy),
              tooltip: 'Refresh Dashboard',
              onPressed: () => _controller.loadDashboard(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (isLoading && data == null) ...[
          const AppPortalSectionSkeleton(
            showHero: false,
            statCards: 4,
            listItems: 4,
          ),
        ] else if (error != null && data == null) ...[
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
                    'Unable to load pharmacy dashboard',
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
                    onPressed: () => _controller.loadDashboard(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ] else if (data != null) ...[
          // Payment Configuration Banner Alert
          if (!data.paymentConfiguration.bankConfigured ||
              !data.paymentConfiguration.upiConfigured) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade900,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Details Action Required',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        Text(
                          'Configure active Bank & UPI details so customers can submit manual payment receipts.',
                          style: AppTypography.caption.copyWith(
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () =>
                        widget.onNavigateToSection?.call('payment-details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.shieldNavy,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Configure',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Operational KPI Grid (Orders)
          Text(
            'Today\'s Order Operations',
            style: AppTypography.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard(
                'New Orders',
                '${data.orders.newCount}',
                Icons.shopping_bag_outlined,
                AppColors.shieldBlue,
                onTap: () => widget.onNavigateToSection?.call('orders'),
              ),
              _buildKpiCard(
                'Preparing',
                '${data.orders.preparingCount}',
                Icons.hourglass_top_outlined,
                Colors.orange.shade800,
                onTap: () => widget.onNavigateToSection?.call('orders'),
              ),
              _buildKpiCard(
                'Ready for Pickup',
                '${data.orders.readyCount}',
                Icons.check_circle_outline,
                AppColors.shieldGreen,
                onTap: () => widget.onNavigateToSection?.call('orders'),
              ),
              _buildKpiCard(
                'Out for Delivery',
                '${data.orders.deliveryCount}',
                Icons.local_shipping_outlined,
                Colors.purple.shade700,
                onTap: () => widget.onNavigateToSection?.call('orders'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Financial & Verification KPI Grid
          Text(
            'Financial & Verification Metrics',
            style: AppTypography.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard(
                'Pending Payments',
                '${data.payments.pendingVerification}',
                Icons.pending_actions_outlined,
                Colors.amber.shade900,
                onTap: () => widget.onNavigateToSection?.call('payments'),
              ),
              _buildKpiCard(
                'Approved Today',
                '${data.payments.approvedToday}',
                Icons.verified_outlined,
                AppColors.shieldGreen,
                subtitle: '₹ ${data.payments.approvedAmountToday.toStringAsFixed(2)}',
                onTap: () => widget.onNavigateToSection?.call('payments'),
              ),
              _buildKpiCard(
                'Completed Today',
                '${data.orders.completedToday}',
                Icons.monetization_on_outlined,
                AppColors.shieldNavy,
                subtitle: '₹ ${data.orders.orderValueToday.toStringAsFixed(2)}',
                onTap: () => widget.onNavigateToSection?.call('orders'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Orders Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: AppTypography.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () =>
                    widget.onNavigateToSection?.call('orders'),
                child: const Text('View All Orders'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (data.recentOrders.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No recent orders.',
                style: AppTypography.caption.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ] else ...[
            ...data.recentOrders.map(
              (o) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(
                    '${o.invoiceNumber} • ${o.customerName}',
                    style: AppTypography.subtitle2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Status: ${o.orderStatus} • ₹ ${o.payableAmount.toStringAsFixed(2)}',
                    style: AppTypography.caption,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.onNavigateToSection?.call('orders'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Recent Payments Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Manual Payment Requests',
                style: AppTypography.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () =>
                    widget.onNavigateToSection?.call('payments'),
                child: const Text('View All Payments'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (data.recentPayments.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No recent payment verification requests.',
                style: AppTypography.caption.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ] else ...[
            ...data.recentPayments.map(
              (p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(
                    '${p.customerName} (${p.customerCode.isNotEmpty ? p.customerCode : 'N/A'})',
                    style: AppTypography.subtitle2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '₹ ${p.amount.toStringAsFixed(2)} via ${p.paymentChannel.replaceAll('_', ' ')}',
                    style: AppTypography.caption,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.status == 'APPROVED'
                          ? AppColors.mintGreen
                          : p.status == 'REJECTED'
                              ? Colors.red.shade100
                              : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.status,
                      style: AppTypography.caption.copyWith(
                        color: p.status == 'APPROVED'
                            ? AppColors.shieldGreen
                            : p.status == 'REJECTED'
                                ? Colors.red.shade800
                                : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () => widget.onNavigateToSection?.call('payments'),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.shieldNavy,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
