import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentAppointmentsScreen extends ConsumerWidget {
  const AgentAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(agentPortalControllerProvider);
    return Card(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Upcoming appointments')),
          ...controller.upcomingAppointments.map(
            (appointment) => ListTile(
              title: Text('${appointment['customerName'] ?? 'Customer'}'),
              subtitle: Text('${appointment['providerName'] ?? 'Provider'}'),
              trailing: Text('${appointment['status'] ?? 'PENDING'}'),
            ),
          ),
        ],
      ),
    );
  }
}
