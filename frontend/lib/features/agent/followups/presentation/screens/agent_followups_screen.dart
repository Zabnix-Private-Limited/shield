import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentFollowUpsScreen extends ConsumerWidget {
  const AgentFollowUpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(agentPortalControllerProvider);
    final tasks = controller.tasks;

    return Card(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Scheduled follow-ups')),
          ...tasks.map(
            (task) => ListTile(
              title: Text('${task['customerName'] ?? 'Customer'}'),
              subtitle: Text('${task['notes'] ?? ''}'),
              trailing: Text('${task['status'] ?? 'PENDING'}'),
            ),
          ),
        ],
      ),
    );
  }
}
