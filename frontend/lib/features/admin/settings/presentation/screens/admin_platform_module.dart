import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminPlatformModule extends StatelessWidget {
  const AdminPlatformModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'System / Platform',
      title: 'Platform runtime and integration health',
      description:
          'A central health board for runtime, queues, integrations, storage, and background workflows that affect operator trust.',
      primaryAction: AdminActionItem(label: 'Open health report', icon: Icons.monitor_heart_outlined),
      secondaryAction: AdminActionItem(label: 'Check integrations', icon: Icons.hub_outlined),
      leftTitle: 'Runtime health',
      leftSubtitle: 'Core platform availability and operational dependencies.',
      leftChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Frontend availability', value: '99.94%', meta: 'last 30 days', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Backend API', value: 'Healthy', meta: 'p95 latency within target', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Storage signing', value: 'Watch', meta: '2 transient failures this morning', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'Background queues', value: 'Lagging', meta: 'document extraction backlog rising', color: AdminColors.danger)),
        ],
      ),
      rightTitle: 'Integration and queue board',
      rightSubtitle: 'The hidden systems operators still depend on every day.',
      rightChild: Column(
        children: [
          AdminQueueTile(title: 'Firebase messaging', subtitle: 'Healthy token registration and push send path', status: 'Healthy', color: AdminColors.success),
          AdminQueueTile(title: 'Cloudflare R2 signed URLs', subtitle: 'One burst of retry behavior during peak hour', status: 'Watch', color: AdminColors.warning),
          AdminQueueTile(title: 'Document extraction service', subtitle: 'OCR queue length up after bulk uploads', status: 'Backlog', color: AdminColors.danger),
        ],
      ),
    );
  }
}
