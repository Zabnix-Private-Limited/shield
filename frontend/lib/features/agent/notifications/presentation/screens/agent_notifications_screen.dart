import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';
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
                  onPressed: () => ref
                      .read(agentPortalControllerProvider)
                      .markAllNotificationsRead(customerId: selectedCustomerId),
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
                  ? const _EmptyNotificationState()
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
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              "You're all caught up.",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'No new notifications match this filter right now.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
