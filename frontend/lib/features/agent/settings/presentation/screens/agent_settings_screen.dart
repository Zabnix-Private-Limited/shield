import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentSettingsScreen extends ConsumerWidget {
  const AgentSettingsScreen({super.key, this.profileOnly = false});

  final bool profileOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(agentPortalControllerProvider);
    final authProfile = controller.authProfile;
    final display = Map<String, dynamic>.from(authProfile['display'] ?? const {});
    final profile = Map<String, dynamic>.from(authProfile['profile'] ?? const {});

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${display['fullName'] ?? 'SHIELD Agent'}'),
              subtitle: Text('${display['designation'] ?? 'Agent'}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Employee code'),
              trailing: Text('${display['employeeCode'] ?? '-'}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mobile'),
              trailing: Text('${display['mobile'] ?? profile['mobile'] ?? '-'}'),
            ),
            if (!profileOnly)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Preferences'),
                subtitle: Text(
                  'Phase 1 keeps settings lightweight: profile visibility and session-safe defaults are ready, while richer persisted preferences can deepen in a later sprint.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
