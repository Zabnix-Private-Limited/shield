import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../customer/shared/widgets/error_card.dart';
import '../../../../customer/shared/widgets/empty_state.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/appointment_card.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/greeting_header.dart';
import '../widgets/marketing_banner_carousel.dart';
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
    _controller = DashboardController.instance..load();
  }

  @override
  void dispose() {
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

        final upcomingVisits = dashboard.summary.upcomingVisitCount;
        final documentCount = dashboard.summary.documentCount;
        final unreadNotificationCount =
            dashboard.summary.unreadNotificationCount;

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          color: AppColors.shieldBlue,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            shrinkWrap: true,
            children: [
              OperationsBannerCarousel(banners: dashboard.banners),
              if (dashboard.banners.isNotEmpty) const SizedBox(height: 20),
              GreetingHeader(
                customer: dashboard.customer,
                membership: dashboard.membership,
                application: dashboard.membershipApplication,
                controller: _controller,
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
                      title: 'Visits',
                      value: '$upcomingVisits',
                      icon: Icons.calendar_month_outlined,
                      color: AppColors.shieldGreen,
                      onTap: () => context.go('/portal/customer/appointments'),
                    ),
                    WalletSummaryCard(
                      title: 'Docs',
                      value: '$documentCount',
                      icon: Icons.description_outlined,
                      color: AppColors.shieldNavy,
                      onTap: () => context.go('/portal/customer/documents'),
                    ),
                    WalletSummaryCard(
                      title: 'Updates',
                      value: '$unreadNotificationCount',
                      icon: Icons.notifications_none_rounded,
                      color: AppColors.shieldLightBlue,
                      onTap: () => context.go('/portal/customer/notifications'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Upcoming Appointments', style: AppTypography.h4),
              const SizedBox(height: 12),
              if (dashboard.appointments.isEmpty)
                EmptyState(
                  title: 'No upcoming appointments',
                  message: 'Book a visit when you are ready to see a provider.',
                  icon: Icons.calendar_month_outlined,
                  action: OutlinedButton(
                    onPressed: () => context.go('/portal/customer/services'),
                    child: const Text('Browse services'),
                  ),
                )
              else
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
