import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/exports.dart';
import '../../application/admin_dashboard_state.dart';
import '../../domain/entities/admin_dashboard_entity.dart';
import '../providers/admin_dashboard_provider.dart';
import '../widgets/admin_dashboard_content.dart';

class AdminDashboardModule extends ConsumerWidget {
  const AdminDashboardModule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(adminDashboardControllerProvider);
    final state = controller.state;
    final dashboard = state.dashboard;

    return AdminPage(
      eyebrow: 'Admin / Live dashboard',
      title: dashboard?.title ?? 'SHIELD command center',
      description: dashboard?.summary ??
          'Connecting the admin dashboard to live backend workspace contracts.',
      primaryAction: _primaryAction(dashboard),
      secondaryAction: _secondaryAction(dashboard),
      metrics: _mapMetrics(dashboard),
      child: _DashboardBody(state: state),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.state});

  final AdminDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(adminDashboardControllerProvider);

    if (state.isLoading && !state.hasData) {
      return const AdminLoading();
    }

    if (state.error != null && !state.hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminError(message: 'Failed to load admin dashboard: ${state.error}'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: controller.load,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Retry dashboard'),
          ),
        ],
      );
    }

    final dashboard = state.dashboard;
    if (dashboard == null) {
      return const AdminEmptyState(
        title: 'Dashboard data is unavailable',
        description:
            'The admin dashboard route completed without returning a usable workspace payload.',
        actionLabel: 'Check the backend dashboard contract',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.error != null) ...[
          AdminError(
            message:
                'Dashboard refresh failed, showing the last successful data snapshot instead.',
          ),
          const SizedBox(height: 12),
        ],
        if (state.isRefreshing) ...[
          const LinearProgressIndicator(color: AdminColors.secondary),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: controller.refresh,
            icon: const Icon(Icons.sync_outlined),
            label: const Text('Refresh live data'),
          ),
        ),
        const SizedBox(height: 12),
        AdminDashboardContent(dashboard: dashboard),
      ],
    );
  }
}

AdminActionItem? _primaryAction(AdminDashboardEntity? dashboard) {
  final action = dashboard?.actions.isNotEmpty == true
      ? dashboard!.actions.first
      : 'Live queue';
  return AdminActionItem(
    label: action,
    icon: Icons.bolt_outlined,
  );
}

AdminActionItem? _secondaryAction(AdminDashboardEntity? dashboard) {
  if (dashboard?.actions.length case final int count when count > 1) {
    return AdminActionItem(
      label: dashboard!.actions[1],
      icon: Icons.tune_outlined,
    );
  }
  return const AdminActionItem(
    label: 'Backend-driven',
    icon: Icons.hub_outlined,
  );
}

List<AdminMetric> _mapMetrics(AdminDashboardEntity? dashboard) {
  if (dashboard == null) {
    return const <AdminMetric>[];
  }

  return dashboard.metrics
      .map(
        (metric) => AdminMetric(
          label: metric.label,
          value: metric.value,
          note: metric.note,
          color: _metricColor(metric),
          icon: _metricIcon(metric),
        ),
      )
      .toList();
}

Color _metricColor(AdminDashboardMetricEntity metric) {
  final normalized = '${metric.label} ${metric.note}'.toLowerCase();
  if (normalized.contains('pending') || normalized.contains('review')) {
    return AdminColors.warning;
  }
  if (normalized.contains('reward') || normalized.contains('point')) {
    return AdminColors.rewards;
  }
  if (normalized.contains('visit') || normalized.contains('appointment')) {
    return AdminColors.visits;
  }
  if (normalized.contains('provider')) {
    return AdminColors.visits;
  }
  if (normalized.contains('active') ||
      normalized.contains('healthy') ||
      normalized.contains('complete')) {
    return AdminColors.success;
  }
  return AdminColors.secondary;
}

IconData _metricIcon(AdminDashboardMetricEntity metric) {
  final normalized = '${metric.label} ${metric.note}'.toLowerCase();
  if (normalized.contains('customer')) {
    return Icons.groups_2_outlined;
  }
  if (normalized.contains('appointment') || normalized.contains('visit')) {
    return Icons.event_available_outlined;
  }
  if (normalized.contains('document')) {
    return Icons.description_outlined;
  }
  if (normalized.contains('provider')) {
    return Icons.local_hospital_outlined;
  }
  if (normalized.contains('wallet') || normalized.contains('credit')) {
    return Icons.account_balance_wallet_outlined;
  }
  return Icons.insights_outlined;
}
