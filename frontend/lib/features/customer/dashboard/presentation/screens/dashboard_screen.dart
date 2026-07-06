import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../shared/domain/customer_access_state.dart';
import '../../../../customer/shared/widgets/error_card.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/appointment_card.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/greeting_header.dart';
import '../widgets/recent_activity.dart';
import '../widgets/wallet_summary_card.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading && !_controller.hasData) {
          return const DashboardShimmer();
        }

        if (_controller.error != null && !_controller.hasData) {
          return ErrorCard(
            title: 'Dashboard unavailable',
            message: 'The customer dashboard preview could not be loaded.',
            onRetry: _controller.load,
          );
        }

        final dashboard = _controller.dashboard;
        if (dashboard == null) {
          return ErrorCard(
            title: 'Dashboard unavailable',
            message: 'No dashboard data is available right now.',
            onRetry: _controller.load,
          );
        }

        final walletBalance = dashboard.wallet.balance;
        final pointsBalance = dashboard.wallet.pointsBalance;
        final upcomingVisits = dashboard.appointments.length;
        final documentCount = dashboard.documents.length;
        final accessState = CustomerAccessState(
          customer: dashboard.customer,
          customerStatus: dashboard.customer.status,
          membership: dashboard.membership,
        );

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          color: AppColors.shieldBlue,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            shrinkWrap: true,
            children: [
              GreetingHeader(
                customer: dashboard.customer,
                membership: dashboard.membership,
                accessState: accessState,
                wallet: dashboard.wallet,
                upcomingVisits: upcomingVisits,
                documentCount: documentCount,
                quickActions: dashboard.quickActions,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) => GridView.count(
                  crossAxisCount: constraints.maxWidth >= 420 ? 2 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth >= 420 ? 2.2 : 2.8,
                  children: [
                    WalletSummaryCard(
                      title: 'Wallet',
                      value: '₹${walletBalance.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.shieldBlue,
                    ),
                    WalletSummaryCard(
                      title: 'Visits',
                      value: '$upcomingVisits',
                      icon: Icons.calendar_month_outlined,
                      color: AppColors.shieldGreen,
                    ),
                    WalletSummaryCard(
                      title: 'Docs',
                      value: '$documentCount',
                      icon: Icons.description_outlined,
                      color: AppColors.shieldNavy,
                    ),
                    WalletSummaryCard(
                      title: 'Points',
                      value: '${pointsBalance.toStringAsFixed(0)} pts',
                      icon: Icons.workspace_premium_outlined,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Upcoming Appointments', style: AppTypography.h4),
              const SizedBox(height: 12),
              ...dashboard.appointments
                  .take(3)
                  .map(
                    (appointment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppointmentCard(appointment: appointment),
                    ),
                  ),
              const SizedBox(height: 14),
              Text('Recent Activity', style: AppTypography.h4),
              const SizedBox(height: 12),
              RecentActivity(
                transactions: dashboard.recentActivity.take(4).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
