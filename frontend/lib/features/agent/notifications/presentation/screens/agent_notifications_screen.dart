import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
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
  String _filter = 'ALL';

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
        onRetry: () => ref.read(agentPortalControllerProvider).refreshWorkspace(),
      );
    }
    final notifications = controller.notifications.where((item) {
      final status = (item['status'] ?? '').toString().toUpperCase();
      if (_filter == 'UNREAD') {
        return status != 'READ';
      }
      if (_filter == 'READ') {
        return status == 'READ';
      }
      return true;
    }).toList();
    final groups = _groupNotifications(notifications);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AgentSectionHeader(
              title: 'Notifications',
              description:
                  'Unread, today, and older alerts are grouped into one timeline so the screen feels like an inbox instead of an empty admin list.',
              actions: [
                FilledButton(
                  onPressed: notifications.isEmpty
                      ? null
                      : () => ref
                          .read(agentPortalControllerProvider)
                          .markAllNotificationsRead(
                            customerId: selectedCustomerId,
                          ),
                  child: const Text('Mark All Read'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChipButton(
                  label: 'All',
                  selected: _filter == 'ALL',
                  onTap: () => setState(() => _filter = 'ALL'),
                ),
                _FilterChipButton(
                  label: 'Unread',
                  selected: _filter == 'UNREAD',
                  onTap: () => setState(() => _filter = 'UNREAD'),
                ),
                _FilterChipButton(
                  label: 'Read',
                  selected: _filter == 'READ',
                  onTap: () => setState(() => _filter = 'READ'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notifications.isEmpty
                  ? _EmptyNotificationState(
                      filter: _filter,
                      onRefresh: () => ref
                          .read(agentPortalControllerProvider)
                          .refreshWorkspace(),
                      onShowAll: () => setState(() => _filter = 'ALL'),
                    )
                  : ListView(
                      children: groups.entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _NotificationGroup(
                                heading: entry.key,
                                items: entry.value,
                                onOpenCustomer: (notification) async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...items.map(
              (notification) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: (notification['status'] ?? '')
                                  .toString()
                                  .toUpperCase() ==
                              'READ'
                          ? Theme.of(context).colorScheme.surfaceContainerHigh
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        (notification['status'] ?? '').toString().toUpperCase() ==
                                'READ'
                            ? Icons.mark_email_read_outlined
                            : Icons.notifications_active_outlined,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title']?.toString() ??
                                      'Notification',
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              _NotificationStatusBadge(
                                label: (notification['status'] ?? '')
                                            .toString()
                                            .toUpperCase() ==
                                        'READ'
                                    ? 'Read'
                                    : 'Unread',
                                isRead: (notification['status'] ?? '')
                                        .toString()
                                        .toUpperCase() ==
                                    'READ',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification['message']?.toString().trim().isNotEmpty ==
                                    true
                                ? notification['message'].toString()
                                : 'A new customer alert is available.',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${notification['customerName'] ?? 'Customer'} • ${_formatDate(notification['sentAt'])}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => onOpenCustomer(notification),
                                child: const Text('Open Customer'),
                              ),
                              if ((notification['status'] ?? '')
                                      .toString()
                                      .toUpperCase() !=
                                  'READ')
                                TextButton(
                                  onPressed: () => onMarkRead(notification),
                                  child: const Text('Mark Read'),
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
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _NotificationStatusBadge extends StatelessWidget {
  const _NotificationStatusBadge({
    required this.label,
    required this.isRead,
  });

  final String label;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final color = isRead ? Colors.green.shade700 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState({
    required this.filter,
    required this.onRefresh,
    required this.onShowAll,
  });

  final String filter;
  final VoidCallback onRefresh;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final isFiltered = filter != 'ALL';
    return AgentEmptyState(
      icon: Icons.notifications_off_outlined,
      title: isFiltered ? 'No Notifications Match This Filter' : "You're all caught up",
      message: isFiltered
          ? 'Try a different filter or refresh the inbox to check for newer customer alerts.'
          : 'No unread or recent notifications need attention right now. The inbox will populate as customer events arrive.',
      actionLabel: 'Refresh',
      onAction: onRefresh,
      secondaryActionLabel: isFiltered ? 'Show All' : null,
      onSecondaryAction: isFiltered ? onShowAll : null,
    );
  }
}

class _NotificationsLoadingState extends StatelessWidget {
  const _NotificationsLoadingState();

  @override
  Widget build(BuildContext context) {
    return AgentPanelCard(
      title: 'Loading Notifications',
      subtitle: 'Fetching unread, today, and older alerts for this workspace.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LinearProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading the notification inbox...'),
        ],
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
      subtitle:
          'The notification inbox could not be loaded, so SHIELD is showing a recoverable error state instead of an empty panel.',
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
    final day =
        local == null ? null : DateTime(local.year, local.month, local.day);
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

String _formatDate(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString());
  if (parsed == null) {
    return '-';
  }
  return DateFormat('dd MMM, h:mm a').format(parsed.toLocal());
}

String _resolveNotificationsError(String message) {
  final normalized = message.trim();
  final lowered = normalized.toLowerCase();
  if (lowered.contains('401') || lowered.contains('unauthorized')) {
    return 'Your SHIELD session expired before notifications finished loading. Sign in again and retry.';
  }
  if (lowered.contains('403') || lowered.contains('forbidden')) {
    return 'This SHIELD role does not have permission to view the notification inbox.';
  }
  if (lowered.contains('network') || lowered.contains('socket')) {
    return 'The notification inbox could not reach the server. Check the connection and retry.';
  }
  return normalized.isEmpty
      ? 'The notification inbox could not be loaded right now.'
      : normalized;
}
