import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminAvailabilityModule extends StatelessWidget {
  const AdminAvailabilityModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Providers / Availability',
      title: 'Availability and capacity board',
      description:
          'Monitor provider schedules, slot health, branch capacity, and care bottlenecks before visit quality degrades.',
      primaryAction: AdminActionItem(label: 'Block slots', icon: Icons.schedule_outlined),
      secondaryAction: AdminActionItem(label: 'Open capacity alerts', icon: Icons.warning_amber_outlined),
      leftTitle: 'Provider schedule health',
      leftSubtitle: 'This is where availability becomes an operational system, not a profile field.',
      leftChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Dermatology', value: '94%', meta: 'Kochi Central near capacity', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'Diagnostics', value: '71%', meta: 'healthy spread', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Homecare', value: '88%', meta: 'travel windows tight', color: AdminColors.visits)),
          AdminHealthRow(item: AdminHealthItem(label: 'Dental', value: '98%', meta: 'Calicut North overloaded', color: AdminColors.danger)),
        ],
      ),
      rightTitle: 'Escalation queue',
      rightSubtitle: 'Capacity incidents that will affect bookings or customer satisfaction.',
      rightChild: Column(
        children: [
          AdminQueueTile(title: 'Calicut North dental overload', subtitle: '4 bookings at risk over the next 48 hours', status: 'Critical', color: AdminColors.danger),
          AdminQueueTile(title: 'Homecare travel conflict', subtitle: 'routing gap between two branches', status: 'Needs review', color: AdminColors.warning),
          AdminQueueTile(title: 'Dermatology peak usage', subtitle: 'consider opening overflow slots for Friday', status: 'Plan', color: AdminColors.visits),
        ],
      ),
    );
  }
}
