import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentDashboardScreen extends ConsumerStatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  ConsumerState<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends ConsumerState<AgentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final summary = controller.summary;
    final performance = controller.performance;

    if (controller.isLoading && controller.workspace.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final widgets = <_DashboardMetric>[
      _DashboardMetric(
        label: "Today's follow-ups",
        value: '${summary['todaysFollowUps'] ?? 0}',
        detail: 'Open the follow-up queue for today',
        route: '/portal/agent/followups',
      ),
      _DashboardMetric(
        label: 'Pending registrations',
        value: '${summary['pendingRegistrations'] ?? 0}',
        detail: 'Continue incomplete and pending onboarding',
        route: '/portal/agent/registration',
      ),
      _DashboardMetric(
        label: "Today's appointments",
        value: '${summary['appointmentsToday'] ?? 0}',
        detail: 'Review and confirm service visits',
        route: '/portal/agent/appointments',
      ),
      _DashboardMetric(
        label: 'Pending documents',
        value: '${summary['pendingDocuments'] ?? 0}',
        detail: 'Upload or validate onboarding files',
        route: '/portal/agent/documents',
      ),
      _DashboardMetric(
        label: 'Open tasks',
        value: '${summary['tasksOpen'] ?? 0}',
        detail: 'See remaining customer follow-ups',
        route: '/portal/agent/followups',
      ),
      _DashboardMetric(
        label: 'Referral leads',
        value: '${summary['newReferrals'] ?? 0}',
        detail: 'Track referral growth and conversion',
        route: '/portal/agent/referrals',
      ),
      _DashboardMetric(
        label: 'Customers added',
        value: '${performance['customersAdded'] ?? 0}',
        detail: 'Review the current month acquisition list',
        route: '/portal/agent/customers',
      ),
      _DashboardMetric(
        label: 'Retention',
        value: '${performance['retentionRate'] ?? 0}%',
        detail: 'Open performance and active customer health',
        route: '/portal/agent/performance',
      ),
      _DashboardMetric(
        label: 'Notifications',
        value: '${summary['unreadNotifications'] ?? 0}',
        detail: 'Read new customer and workflow alerts',
        route: '/portal/agent/notifications',
      ),
      _DashboardMetric(
        label: 'Monthly performance',
        value: '${performance['conversionRate'] ?? 0}%',
        detail: 'Open the performance board',
        route: '/portal/agent/performance',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widgets
              .map(
                (metric) => _ClickableMetricCard(
                  metric: metric,
                  onTap: () => context.go(metric.route),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 980;
            final left = Column(
              children: [
                _ListSection(
                  title: 'Recent activity',
                  emptyMessage: 'No recent activity yet.',
                  items: controller.recentActivity,
                  builder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_humanize(item['activityType'])),
                    subtitle: Text(
                      '${item['customerName'] ?? 'Customer'} • ${item['notes'] ?? 'No remarks'}',
                    ),
                    trailing: Text(_formatDateTime(item['createdAt'])),
                  ),
                ),
                const SizedBox(height: 16),
                _ListSection(
                  title: 'Upcoming appointments',
                  emptyMessage: 'No upcoming visits are scheduled.',
                  actionLabel: 'Open appointments',
                  onActionTap: () => context.go('/portal/agent/appointments'),
                  items: controller.upcomingAppointments.take(6).toList(),
                  builder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item['customerName'] ?? 'Customer'}'),
                    subtitle: Text(
                      '${item['providerName'] ?? 'Provider'} • ${_humanize(item['appointmentType'])}',
                    ),
                    trailing: Text(_formatDateTime(item['appointmentDate'])),
                  ),
                ),
              ],
            );
            final right = Column(
              children: [
                _ListSection(
                  title: 'Tasks to close next',
                  emptyMessage: 'No follow-ups are pending.',
                  actionLabel: 'Open follow-ups',
                  onActionTap: () => context.go('/portal/agent/followups'),
                  items: controller.tasks.take(6).toList(),
                  builder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item['customerName'] ?? 'Customer'}'),
                    subtitle: Text('${item['notes'] ?? 'No remarks'}'),
                    trailing: Text(_humanize(item['status'])),
                  ),
                ),
                const SizedBox(height: 16),
                _ListSection(
                  title: 'Unread notifications',
                  emptyMessage: 'No unread notifications right now.',
                  actionLabel: 'Open notifications',
                  onActionTap: () => context.go('/portal/agent/notifications'),
                  items: controller.notifications
                      .where(
                        (item) =>
                            (item['status'] ?? '').toString().toUpperCase() != 'READ',
                      )
                      .take(6)
                      .toList(),
                  builder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item['title'] ?? 'Notification'}'),
                    subtitle: Text(
                      '${item['customerName'] ?? 'Customer'} • ${item['message'] ?? ''}',
                    ),
                    trailing: Text(_formatDateTime(item['sentAt'])),
                  ),
                ),
              ],
            );

            if (stack) {
              return Column(children: [left, const SizedBox(height: 16), right]);
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 16),
                Expanded(child: right),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.route,
  });

  final String label;
  final String value;
  final String detail;
  final String route;
}

class _ClickableMetricCard extends StatelessWidget {
  const _ClickableMetricCard({required this.metric, required this.onTap});

  final _DashboardMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                Text(metric.value, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(metric.detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.emptyMessage,
    required this.items,
    required this.builder,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String emptyMessage;
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic>) builder;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                ),
                if (actionLabel != null)
                  TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(emptyMessage)
            else
              ...items.map(builder),
          ],
        ),
      ),
    );
  }
}

String _humanize(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) {
    return '-';
  }
  return text
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatDateTime(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString());
  if (parsed == null) {
    return '-';
  }
  return DateFormat('dd MMM, h:mm a').format(parsed.toLocal());
}
