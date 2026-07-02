import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentPerformanceScreen extends ConsumerWidget {
  const AgentPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performance = ref.watch(agentPortalControllerProvider).performance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: performance.entries
              .map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  trailing: Text('${entry.value}'),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
