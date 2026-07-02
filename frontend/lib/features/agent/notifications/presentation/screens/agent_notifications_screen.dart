import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentNotificationsScreen extends ConsumerStatefulWidget {
  const AgentNotificationsScreen({super.key});

  @override
  ConsumerState<AgentNotificationsScreen> createState() => _AgentNotificationsScreenState();
}

class _AgentNotificationsScreenState extends ConsumerState<AgentNotificationsScreen> {
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Notification center',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                DropdownButton<String>(
                  value: _filter,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All')),
                    DropdownMenuItem(value: 'UNREAD', child: Text('Unread')),
                    DropdownMenuItem(value: 'READ', child: Text('Read')),
                  ],
                  onChanged: (value) => setState(() => _filter = value ?? 'ALL'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => ref
                      .read(agentPortalControllerProvider)
                      .markAllNotificationsRead(customerId: selectedCustomerId),
                  child: const Text('Mark all read'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (notifications.isEmpty)
              const Text('No notifications match this filter.')
            else
              ...notifications.map(
                (notification) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${notification['title'] ?? 'Notification'}'),
                  subtitle: Text(
                    '${notification['customerName'] ?? 'Customer'} • ${notification['message'] ?? ''}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(_formatDate(notification['sentAt'])),
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final customerId =
                              notification['customerId']?.toString() ?? '';
                          if (customerId.isEmpty) {
                            return;
                          }
                          await ref
                              .read(agentPortalControllerProvider)
                              .selectCustomer(customerId);
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Customer workspace is ready in the Customers section.',
                              ),
                            ),
                          );
                        },
                        child: const Text('Open customer'),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(agentPortalControllerProvider)
                            .markNotificationRead(
                              notification['id']?.toString() ?? '',
                            ),
                        child: Text(
                          (notification['status'] ?? '').toString().toUpperCase() == 'READ'
                              ? 'Read'
                              : 'Mark read',
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

String _formatDate(dynamic value) {
  final parsed = DateTime.tryParse((value ?? '').toString());
  if (parsed == null) {
    return '-';
  }
  return DateFormat('dd MMM, h:mm a').format(parsed.toLocal());
}
