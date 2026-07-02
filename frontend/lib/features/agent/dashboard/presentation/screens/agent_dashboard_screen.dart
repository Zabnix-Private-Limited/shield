import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentDashboardScreen extends ConsumerStatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  ConsumerState<AgentDashboardScreen> createState() =>
      _AgentDashboardScreenState();
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

    final now = DateTime.now();
    final tasksToday = controller.tasks.where(
      (item) => _sameDay(item['dueDate'], now),
    );
    final tasksOverdue = controller.tasks.where(
      (item) => _isOverdue(item['dueDate']),
    );
    final urgentAlerts = controller.notifications.where(
      (item) =>
          (item['priority'] ?? '').toString().toUpperCase() == 'HIGH' ||
          (item['status'] ?? '').toString().toUpperCase() != 'READ',
    );

    final taskMetrics = [
      _TaskMetric(
        value: '${summary['pendingRegistrations'] ?? 0}',
        label: 'Pending registrations',
        helper: 'Drafts or incomplete customer onboarding records.',
        icon: Icons.assignment_ind_outlined,
        route: '/portal/agent/registration',
        color: Colors.orange.shade700,
      ),
      _TaskMetric(
        value: '${summary['pendingDocuments'] ?? 0}',
        label: 'Pending doc uploads',
        helper: 'Customers still waiting for required files.',
        icon: Icons.upload_file_outlined,
        route: '/portal/agent/documents',
        color: Colors.deepOrange.shade700,
      ),
      _TaskMetric(
        value: '${summary['todaysFollowUps'] ?? tasksToday.length}',
        label: 'Today’s follow-ups',
        helper: 'Scheduled customer calls and field follow-through.',
        icon: Icons.event_note_outlined,
        route: '/portal/agent/followups',
        color: Colors.blue.shade700,
      ),
      _TaskMetric(
        value: '${tasksOverdue.length}',
        label: 'Overdue follow-ups',
        helper: 'Items that need attention before anything else.',
        icon: Icons.warning_amber_rounded,
        route: '/portal/agent/followups',
        color: Colors.red.shade700,
      ),
      _TaskMetric(
        value: '${summary['appointmentsToday'] ?? 0}',
        label: 'Upcoming visits',
        helper: 'Customer visits already in the calendar.',
        icon: Icons.calendar_month_outlined,
        route: '/portal/agent/appointments',
        color: Colors.green.shade700,
      ),
      _TaskMetric(
        value: '${urgentAlerts.length}',
        label: 'High priority alerts',
        helper: 'Unread or urgent alerts waiting for action.',
        icon: Icons.notification_important_outlined,
        route: '/portal/agent/notifications',
        color: Colors.purple.shade700,
      ),
    ];

    final supportingMetrics = [
      _TaskMetric(
        value: '${controller.customers.length}',
        label: 'Today’s customer count',
        helper: 'Customers currently assigned to this workspace.',
        icon: Icons.groups_outlined,
        route: '/portal/agent/customers',
        color: Theme.of(context).colorScheme.primary,
      ),
      _TaskMetric(
        value: '${summary['appointmentsToday'] ?? 0}',
        label: 'Today’s visit count',
        helper: 'Visits that need coordination today.',
        icon: Icons.route_outlined,
        route: '/portal/agent/appointments',
        color: Colors.teal.shade700,
      ),
      _TaskMetric(
        value: '${performance['retentionRate'] ?? 0}%',
        label: 'Retention',
        helper: 'Customer retention across the current portfolio.',
        icon: Icons.favorite_outline,
        route: '/portal/agent/performance',
        color: Colors.green.shade700,
      ),
      _TaskMetric(
        value: '${performance['conversionRate'] ?? 0}%',
        label: 'Monthly target',
        helper: 'Current conversion momentum for the month.',
        icon: Icons.track_changes_outlined,
        route: '/portal/agent/performance',
        color: Colors.indigo.shade700,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentSectionHeader(
          title: 'Good morning, $firstName',
          description:
              'Start with what needs action today. Statistics stay visible, but customer tasks, overdue follow-ups, documents, and visits lead the workspace.',
        ),
        const SizedBox(height: 12),
        AgentPanelCard(
          title: 'Today’s Tasks',
          subtitle:
              'This section answers what needs to happen next before the broader monthly metrics take over.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: taskMetrics
                .map(
                  (metric) => AgentMetricCard(
                    value: metric.value,
                    label: metric.label,
                    helper: metric.helper,
                    icon: metric.icon,
                    color: metric.color,
                    onTap: () => context.go(metric.route),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        AgentPanelCard(
          title: 'Quick Actions',
          subtitle:
              'The main operational actions stay large and obvious for field use on smaller laptops and tablets.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AgentActionTile(
                label: 'Register Customer',
                icon: Icons.person_add_alt_1_outlined,
                onTap: () => context.go('/portal/agent/registration'),
              ),
              AgentActionTile(
                label: 'Upload Documents',
                icon: Icons.upload_file_outlined,
                onTap: () => context.go('/portal/agent/documents'),
              ),
              AgentActionTile(
                label: 'Create Follow-Up',
                icon: Icons.playlist_add_check_circle_outlined,
                onTap: () => context.go('/portal/agent/followups'),
              ),
              AgentActionTile(
                label: 'Schedule Visit',
                icon: Icons.event_available_outlined,
                onTap: () => context.go('/portal/agent/appointments'),
              ),
              AgentActionTile(
                label: 'Open Customers',
                icon: Icons.groups_outlined,
                onTap: () => context.go('/portal/agent/customers'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 1080;
            final primary = Column(
              children: [
                _TimelineSection(
                  title: 'Urgent Actions',
                  emptyMessage:
                      'No urgent actions are waiting. Today looks under control.',
                  actionLabel: 'Open follow-ups',
                  onActionTap: () => context.go('/portal/agent/followups'),
                  items: [
                    ...controller.tasks.take(4).map(
                      (item) => _TimelineItemData(
                        title: item['customerName']?.toString() ?? 'Customer',
                        subtitle:
                            '${_humanize(item['status'])} • ${item['notes'] ?? 'No remarks'}',
                        timeLabel: _formatDateTime(item['dueDate']),
                        icon: _isOverdue(item['dueDate'])
                            ? Icons.priority_high_rounded
                            : Icons.assignment_outlined,
                      ),
                    ),
                    ...urgentAlerts.take(2).map(
                      (item) => _TimelineItemData(
                        title: item['title']?.toString() ?? 'Alert',
                        subtitle: item['message']?.toString().trim().isNotEmpty ==
                                true
                            ? item['message'].toString()
                            : 'Agent attention required.',
                        timeLabel: _formatDateTime(item['sentAt']),
                        icon: Icons.notification_important_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TimelineSection(
                  title: 'Activity',
                  emptyMessage: 'No recent registrations, uploads, or customer updates yet.',
                  actionLabel: 'Open customers',
                  onActionTap: () => context.go('/portal/agent/customers'),
                  items: controller.recentActivity.take(6).map(
                    (item) {
                      final activityType =
                          _humanize(item['activityType']).toLowerCase();
                      return _TimelineItemData(
                        title: item['customerName']?.toString() ?? 'Customer',
                        subtitle:
                            '${_humanize(item['activityType'])} • ${item['notes'] ?? 'No remarks'}',
                        timeLabel: _formatDateTime(item['createdAt']),
                        icon: activityType.contains('upload')
                            ? Icons.upload_file_outlined
                            : activityType.contains('register')
                                ? Icons.person_add_alt_1_outlined
                                : Icons.history_outlined,
                      );
                    },
                  ).toList(),
                ),
              ],
            );

            final secondary = Column(
              children: [
                _TimelineSection(
                  title: 'Upcoming Visits',
                  emptyMessage: 'No visits are scheduled yet.',
                  actionLabel: 'Open visits',
                  onActionTap: () => context.go('/portal/agent/appointments'),
                  items: controller.upcomingAppointments.take(6).map(
                    (item) => _TimelineItemData(
                      title: item['customerName']?.toString() ?? 'Customer',
                      subtitle:
                          '${item['providerName'] ?? 'Provider'} • ${_humanize(item['appointmentType'])}',
                      timeLabel: _formatDateTime(item['appointmentDate']),
                      icon: Icons.calendar_month_outlined,
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 12),
                AgentPanelCard(
                  title: 'Metrics',
                  subtitle:
                      'Monthly health stays visible, but it no longer dominates the top of the dashboard.',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: supportingMetrics
                        .map(
                          (metric) => AgentMetricCard(
                            value: metric.value,
                            label: metric.label,
                            helper: metric.helper,
                            icon: metric.icon,
                            color: metric.color,
                            onTap: () => context.go(metric.route),
                            width: 200,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            );

            if (stack) {
              return Column(
                children: [
                  primary,
                  const SizedBox(height: 12),
                  secondary,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: primary),
                const SizedBox(width: 12),
                Expanded(flex: 5, child: secondary),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({
    required this.title,
    required this.emptyMessage,
    required this.items,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String emptyMessage;
  final List<_TimelineItemData> items;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return AgentPanelCard(
      title: title,
      action: actionLabel == null
          ? null
          : TextButton(
              onPressed: onActionTap,
              child: Text(actionLabel!),
            ),
      child: items.isEmpty
          ? AgentEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nothing waiting here',
              message: emptyMessage,
            )
          : Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            child: Icon(item.icon, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(item.subtitle),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.timeLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _TaskMetric {
  const _TaskMetric({
    required this.value,
    required this.label,
    required this.helper,
    required this.icon,
    required this.route,
    required this.color,
  });

  final String value;
  final String label;
  final String helper;
  final IconData icon;
  final String route;
  final Color color;
}

class _TimelineItemData {
  const _TimelineItemData({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final IconData icon;
}

bool _sameDay(dynamic value, DateTime now) {
  final parsed = DateTime.tryParse((value ?? '').toString())?.toLocal();
  if (parsed == null) {
    return false;
  }
  return parsed.year == now.year &&
      parsed.month == now.month &&
      parsed.day == now.day;
}

bool _isOverdue(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString())?.toLocal();
  if (parsed == null) {
    return false;
  }
  return parsed.isBefore(DateTime.now());
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
      .map(
        (part) =>
            part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
      )
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
