import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

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
    final authProfile = controller.authProfile;
    final display = Map<String, dynamic>.from(authProfile['display'] ?? const {});
    final firstName =
        display['fullName']?.toString().trim().split(' ').firstOrNull ?? 'Agent';

    if (controller.isLoading && controller.workspace.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final cards = <_DashboardMetric>[
      _DashboardMetric(
        label: "Today's registrations",
        value: '${summary['pendingRegistrations'] ?? 0}',
        detail: 'Customers still waiting to be completed or submitted.',
        route: '/portal/agent/registration',
      ),
      _DashboardMetric(
        label: "Today's follow-ups",
        value: '${summary['todaysFollowUps'] ?? 0}',
        detail: 'Customer calls or visits planned for today.',
        route: '/portal/agent/followups',
      ),
      _DashboardMetric(
        label: 'Appointments',
        value: '${summary['appointmentsToday'] ?? 0}',
        detail: 'Visits already scheduled for today.',
        route: '/portal/agent/appointments',
      ),
      _DashboardMetric(
        label: 'Pending documents',
        value: '${summary['pendingDocuments'] ?? 0}',
        detail: 'Required customer files still waiting for upload or validation.',
        route: '/portal/agent/documents',
      ),
      _DashboardMetric(
        label: 'Retention',
        value: '${performance['retentionRate'] ?? 0}%',
        detail: 'Active customer retention across your current portfolio.',
        route: '/portal/agent/performance',
      ),
      _DashboardMetric(
        label: 'Monthly target',
        value: '${performance['conversionRate'] ?? 0}%',
        detail: 'Current conversion momentum for this month.',
        route: '/portal/agent/performance',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentSectionHeader(
          title: 'Good morning, $firstName',
          description:
              'Start with today’s customer tasks, then move into registrations, visits, and document follow-through.',
          actions: [
            FilledButton.icon(
              onPressed: () => context.go('/portal/agent/registration'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Register Customer'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/portal/agent/followups'),
              icon: const Icon(Icons.event_note_outlined),
              label: const Text('Open Follow-Ups'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
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
                const _QuickActionStrip(
                  actions: [
                    _QuickAction(
                      label: 'Register Customer',
                      icon: Icons.person_add_alt_1_outlined,
                      route: '/portal/agent/registration',
                    ),
                    _QuickAction(
                      label: 'Schedule Visit',
                      icon: Icons.calendar_month_outlined,
                      route: '/portal/agent/appointments',
                    ),
                    _QuickAction(
                      label: 'Upload Documents',
                      icon: Icons.upload_file_outlined,
                      route: '/portal/agent/documents',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ListSection(
                  title: 'Today’s tasks',
                  emptyMessage: 'No urgent follow-up tasks are waiting right now.',
                  actionLabel: 'View all',
                  onActionTap: () => context.go('/portal/agent/followups'),
                  items: controller.tasks.take(5).toList(),
                  builder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item['customerName'] ?? 'Customer'}'),
                    subtitle: Text(
                      '${_humanize(item['status'])} • ${item['notes'] ?? 'No remarks'}',
                    ),
                    trailing: Text(_formatDateTime(item['dueDate'])),
                  ),
                ),
                const SizedBox(height: 16),
                _ListSection(
                  title: 'Recent customers',
                  emptyMessage: 'No recent customers are available yet.',
                  actionLabel: 'Open customers',
                  onActionTap: () => context.go('/portal/agent/customers'),
                  items: controller.customers.take(5).toList(),
                  builder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item['fullName'] ?? 'Customer'}'),
                    subtitle: Text(
                      '${item['mobile'] ?? ''} • ${_humanize(item['membershipStatus'])}',
                    ),
                    trailing: Chip(
                      label: Text(_humanize(item['status'])),
                    ),
                  ),
                ),
              ],
            );
            final right = Column(
              children: [
                _ListSection(
                  title: 'Upcoming visits',
                  emptyMessage: 'No upcoming visits are scheduled.',
                  actionLabel: 'Open visits',
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
                const SizedBox(height: 16),
                _ListSection(
                  title: 'Recent activity',
                  emptyMessage: 'No recent activity yet.',
                  items: controller.recentActivity.take(6).toList(),
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
                  title: 'Notifications',
                  emptyMessage: 'No unread notifications right now.',
                  actionLabel: 'Open notifications',
                  onActionTap: () => context.go('/portal/agent/notifications'),
                  items: controller.notifications
                      .where(
                        (item) =>
                            (item['status'] ?? '').toString().toUpperCase() != 'READ',
                      )
                      .take(5)
                      .toList(),
                  builder: (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${item['title'] ?? 'Notification'}'),
                    subtitle: Text('${item['message'] ?? ''}'),
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

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _QuickActionStrip extends StatelessWidget {
  const _QuickActionStrip({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions
                  .map(
                    (action) => SizedBox(
                      width: 180,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(action.route),
                        icon: Icon(action.icon),
                        label: Text(action.label),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
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
            if (items.isEmpty) Text(emptyMessage) else ...items.map(builder),
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

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
