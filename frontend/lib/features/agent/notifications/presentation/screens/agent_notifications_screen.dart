import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_design_system.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentNotificationsScreen extends ConsumerStatefulWidget {
  const AgentNotificationsScreen({super.key});

  @override
  ConsumerState<AgentNotificationsScreen> createState() =>
      _AgentNotificationsScreenState();
}

class _AgentNotificationsScreenState
    extends ConsumerState<AgentNotificationsScreen> {
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
    final selectedCustomerId = controller.selectedCustomerId;
    if (controller.isLoading && controller.workspace.isEmpty) {
      return const _NotificationsLoadingState();
    }
    if ((controller.error ?? '').trim().isNotEmpty &&
        controller.workspace.isEmpty) {
      return _NotificationsErrorState(
        message: _resolveNotificationsError(controller.error!),
        onRetry: () =>
            ref.read(agentPortalControllerProvider).refreshWorkspace(),
      );
    }
    final notifications = controller.notifications;
    final groups = _groupNotifications(notifications);
    final unreadCount = notifications.where((item) {
      return (item['status'] ?? '').toString().toUpperCase() != 'READ';
    }).length;
    final bodyHeight = (MediaQuery.sizeOf(context).height - 320).clamp(
      360.0,
      1200.0,
    );

    return AgentWorkspaceSurface(
      padding: AgentSpacing.compactInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgentSectionHeader(
            title: 'Notifications',
            description: 'A grouped inbox for customer and system updates.',
            actions: [
              AgentGhostButton(
                onPressed: () =>
                    ref.read(agentPortalControllerProvider).refreshWorkspace(),
                icon: const Icon(Icons.refresh_rounded),
                label: 'Refresh',
              ),
              AgentPrimaryButton(
                onPressed: unreadCount == 0
                    ? null
                    : () => ref
                          .read(agentPortalControllerProvider)
                          .markAllNotificationsRead(
                            customerId: selectedCustomerId,
                          ),
                label: 'Mark All Read',
              ),
            ],
          ),
          AgentUi.gapH(AgentSpacing.sectionGap),
          Wrap(
            spacing: AgentSpacing.xs,
            runSpacing: AgentSpacing.xs,
            children: [
              AgentStatusBadge(
                label: '$unreadCount unread',
                color: unreadCount == 0
                    ? AgentColors.accentSlate
                    : AgentColors.accentBlue,
                icon: Icons.mark_email_unread_outlined,
              ),
              AgentStatusBadge(
                label: '${groups['Today']?.length ?? 0} today',
                color: AgentColors.accentTeal,
                icon: Icons.today_outlined,
              ),
              AgentStatusBadge(
                label: '${notifications.length} total',
                color: AgentColors.accentPurple,
                icon: Icons.notifications_active_outlined,
              ),
            ],
          ),
          AgentUi.gapH(AgentSpacing.sectionGap),
          SizedBox(
            height: bodyHeight,
            child: notifications.isEmpty
                ? SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: bodyHeight),
                      child: const _EmptyNotificationState(),
                    ),
                  )
                : ListView(
                    children: groups.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NotificationGroup(
                              heading: entry.key,
                              items: entry.value,
                              onOpenCustomer: (notification) async {
                                final messenger = ScaffoldMessenger.of(context);
                                final customerId =
                                    notification['customerId']?.toString() ??
                                    '';
                                if (customerId.isEmpty) {
                                  return;
                                }
                                await ref
                                    .read(agentPortalControllerProvider)
                                    .selectCustomer(customerId);
                                if (!context.mounted) {
                                  return;
                                }
                                context.go('/portal/agent/customers');
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Customer workspace is ready in Customers.',
                                    ),
                                  ),
                                );
                              },
                              onMarkRead: (notification) => ref
                                  .read(agentPortalControllerProvider)
                                  .markNotificationRead(
                                    notification['id']?.toString() ?? '',
                                  ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.heading,
    required this.items,
    required this.onOpenCustomer,
    required this.onMarkRead,
  });

  final String heading;
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onOpenCustomer;
  final ValueChanged<Map<String, dynamic>> onMarkRead;

  @override
  Widget build(BuildContext context) {
    return AgentPanelCard(
      title: heading,
      child: Column(
        children: items
            .map(
              (notification) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AgentInsetSurface(
                  padding: AgentSpacing.compactInsets,
                  backgroundColor:
                      (notification['status'] ?? '').toString().toUpperCase() ==
                          'READ'
                      ? null
                      : Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            (notification['status'] ?? '')
                                    .toString()
                                    .toUpperCase() ==
                                'READ'
                            ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
                            : Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          _initials(notification['customerName']),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      AgentUi.gapW(AgentSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title']?.toString() ??
                                        'Notification',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                                AgentUi.gapW(AgentSpacing.xs),
                                Text(
                                  _formatTime(notification['sentAt']),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            AgentUi.gapH(AgentSpacing.xxs),
                            Text(
                              notification['message']
                                          ?.toString()
                                          .trim()
                                          .isNotEmpty ==
                                      true
                                  ? notification['message'].toString()
                                  : 'A new customer alert is available.',
                            ),
                            AgentUi.gapH(AgentSpacing.xs),
                            Wrap(
                              spacing: AgentSpacing.xs,
                              runSpacing: AgentSpacing.xs,
                              children: [
                                AgentStatusBadge(
                                  label:
                                      notification['customerName']
                                          ?.toString()
                                          .ifBlank('Customer') ??
                                      'Customer',
                                  color: AgentColors.accentSlate,
                                  icon: Icons.person_outline,
                                ),
                                AgentStatusBadge(
                                  label:
                                      (notification['status'] ?? '')
                                              .toString()
                                              .toUpperCase() ==
                                          'READ'
                                      ? 'Read'
                                      : 'Unread',
                                  color:
                                      (notification['status'] ?? '')
                                              .toString()
                                              .toUpperCase() ==
                                          'READ'
                                      ? AgentColors.success
                                      : AgentColors.warning,
                                  icon:
                                      (notification['status'] ?? '')
                                              .toString()
                                              .toUpperCase() ==
                                          'READ'
                                      ? Icons.mark_email_read_outlined
                                      : Icons.mark_email_unread_outlined,
                                ),
                              ],
                            ),
                            AgentUi.gapH(AgentSpacing.xs),
                            Wrap(
                              spacing: AgentSpacing.xs,
                              runSpacing: AgentSpacing.xs,
                              children: [
                                AgentGhostButton(
                                  onPressed: () => onOpenCustomer(notification),
                                  label: 'Open Customer',
                                ),
                                if ((notification['status'] ?? '')
                                        .toString()
                                        .toUpperCase() !=
                                    'READ')
                                  AgentGhostButton(
                                    onPressed: () => onMarkRead(notification),
                                    label: 'Mark Read',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return const AgentEmptyState(
      icon: Icons.notifications_off_outlined,
      title: 'You are all caught up',
      message: 'New customer and system alerts will appear here.',
    );
  }
}

class _NotificationsLoadingState extends StatelessWidget {
  const _NotificationsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const AgentPanelCard(
      title: 'Loading Notifications',
      subtitle: 'Loading the inbox for this workspace.',
      child: AgentLoadingState(
        title: 'Loading notification inbox',
        message: 'Loading the notification inbox...',
      ),
    );
  }
}

class _NotificationsErrorState extends StatelessWidget {
  const _NotificationsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AgentPanelCard(
      title: 'Notifications Unavailable',
      subtitle: 'The inbox could not be loaded right now.',
      child: AgentErrorState(
        title: 'We could not load notifications',
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}

Map<String, List<Map<String, dynamic>>> _groupNotifications(
  List<Map<String, dynamic>> notifications,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final groups = <String, List<Map<String, dynamic>>>{};

  for (final notification in notifications) {
    final parsed = DateTime.tryParse((notification['sentAt'] ?? '').toString());
    final local = parsed?.toLocal();
    final day = local == null
        ? null
        : DateTime(local.year, local.month, local.day);
    final label = day == today
        ? 'Today'
        : day == yesterday
        ? 'Yesterday'
        : 'Earlier';
    groups.putIfAbsent(label, () => <Map<String, dynamic>>[]).add(notification);
  }

  return {
    if (groups.containsKey('Today')) 'Today': groups['Today']!,
    if (groups.containsKey('Yesterday')) 'Yesterday': groups['Yesterday']!,
    if (groups.containsKey('Earlier')) 'Earlier': groups['Earlier']!,
  };
}

String _formatTime(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString());
  if (parsed == null) {
    return '-';
  }
  return DateFormat('h:mm a').format(parsed.toLocal());
}

String _initials(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) {
    return 'C';
  }
  final parts = text.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _resolveNotificationsError(String message) {
  final normalized = message.trim();
  final lowered = normalized.toLowerCase();
  if (lowered.contains('401') || lowered.contains('unauthorized')) {
    return 'Your SHIELD session expired before notifications finished loading.';
  }
  if (lowered.contains('403') || lowered.contains('forbidden')) {
    return 'This SHIELD role does not have permission to view the inbox.';
  }
  if (lowered.contains('network') || lowered.contains('socket')) {
    return 'The notification inbox could not reach the server.';
  }
  return normalized.isEmpty
      ? 'The notification inbox could not be loaded right now.'
      : normalized;
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
