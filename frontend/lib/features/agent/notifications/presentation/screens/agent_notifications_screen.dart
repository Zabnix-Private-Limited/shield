import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentNotificationsScreen extends ConsumerWidget {
  const AgentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(agentPortalControllerProvider);
    return Card(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Assigned notifications')),
          ...controller.notifications.map(
            (notification) => ListTile(
              title: Text('${notification['title'] ?? 'Notification'}'),
              subtitle: Text('${notification['customerName'] ?? ''}'),
              trailing: Text('${notification['status'] ?? 'UNREAD'}'),
            ),
          ),
        ],
      ),
    );
  }
}
