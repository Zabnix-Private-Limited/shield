import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminReportsModule extends StatelessWidget {
  const AdminReportsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Analytics / Reports',
      title: 'Report builder and export governance',
      description:
          'A structured builder for datasets, filters, columns, grouping, preview, and export history instead of one-click placeholder cards.',
      primaryAction: AdminActionItem(label: 'Run report', icon: Icons.analytics_outlined),
      secondaryAction: AdminActionItem(label: 'Save template', icon: Icons.bookmark_border_outlined),
      leftTitle: 'Report builder',
      leftSubtitle: 'Choose dataset, filters, columns, grouping, preview, and export.',
      leftChild: AdminBuilderSteps(
        steps: [
          AdminBuilderStepItem(step: '1', label: 'Choose dataset', description: 'Customers, visits, memberships, wallet, referral, provider, branch'),
          AdminBuilderStepItem(step: '2', label: 'Add filters', description: 'Branch, provider, role, lifecycle status, date range'),
          AdminBuilderStepItem(step: '3', label: 'Choose columns', description: 'Operational and analytical fields only'),
          AdminBuilderStepItem(step: '4', label: 'Group and preview', description: 'Verify structure before export'),
          AdminBuilderStepItem(step: '5', label: 'Export or schedule', description: 'CSV, XLSX, PDF, or recurring delivery'),
        ],
      ),
      rightTitle: 'Saved and scheduled reports',
      rightSubtitle: 'The report center should feel operational, not decorative.',
      rightChild: Column(
        children: [
          AdminQueueTile(title: 'Daily verification backlog', subtitle: 'Scheduled every 08:00 to central ops', status: 'Scheduled', color: AdminColors.secondary),
          AdminQueueTile(title: 'Weekly agent retention performance', subtitle: 'Sent to branch managers on Monday', status: 'Saved', color: AdminColors.success),
          AdminQueueTile(title: 'Monthly wallet audit pack', subtitle: 'Pending review after pricing rule changes', status: 'Review', color: AdminColors.warning),
        ],
      ),
    );
  }
}
