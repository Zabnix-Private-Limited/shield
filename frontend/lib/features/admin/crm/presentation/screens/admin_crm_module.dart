import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminCrmModule extends StatelessWidget {
  const AdminCrmModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Operations / CRM',
      title: 'CRM workload and escalation board',
      description:
          'Monitor call queues, pending work, escalations, and retention pressure across the CRM organization.',
      primaryAction: AdminActionItem(label: 'Open escalations', icon: Icons.support_agent_outlined),
      secondaryAction: AdminActionItem(label: 'Assign campaign', icon: Icons.campaign_outlined),
      leftTitle: 'Today work',
      leftSubtitle: 'Queue ownership across inbound and outbound retention activity.',
      leftChild: Column(
        children: [
          AdminQueueTile(title: 'Renewal reminders', subtitle: '48 customers due in 3 days across Kochi and Thrissur', status: 'In progress', color: AdminColors.secondary),
          AdminQueueTile(title: 'Missed-visit callbacks', subtitle: '17 customers need rebooking follow-up today', status: 'Urgent', color: AdminColors.warning),
          AdminQueueTile(title: 'Complaint escalations', subtitle: '6 unresolved cases now beyond 24-hour expectation', status: 'Critical', color: AdminColors.danger),
        ],
      ),
      rightTitle: 'CRM performance',
      rightSubtitle: 'Operators, resolution pace, and handoff quality.',
      rightChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Calls completed', value: '182', meta: 'today across all CRM executives', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Average resolution time', value: '11m', meta: 'down 14% week over week', color: AdminColors.secondary)),
          AdminHealthRow(item: AdminHealthItem(label: 'Escalation rate', value: '6.2%', meta: 'slightly above target', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'Missed callbacks', value: '9', meta: '2 require manager review', color: AdminColors.danger)),
        ],
      ),
    );
  }
}
