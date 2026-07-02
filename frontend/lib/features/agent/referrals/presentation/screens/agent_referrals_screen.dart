import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentReferralsScreen extends ConsumerWidget {
  const AgentReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerWorkspace =
        ref.watch(agentPortalControllerProvider).selectedCustomerWorkspace;
    final referralSummary =
        Map<String, dynamic>.from(customerWorkspace['referralSummary'] ?? const {});
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: referralSummary.entries
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
