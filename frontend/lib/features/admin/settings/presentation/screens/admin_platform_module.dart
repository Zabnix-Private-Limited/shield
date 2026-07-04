import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminPlatformModule extends StatelessWidget {
  const AdminPlatformModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminConsolePage(
      title: 'Platform',
      subtitle:
          'System health should render as a live dependency dashboard for infrastructure, queues, storage, and integration status instead of fake uptime tiles.',
      actions: const [
        AdminActionItem(label: 'Check integrations', icon: Icons.hub_outlined),
        AdminActionItem(label: 'Open health report', icon: Icons.monitor_heart_outlined),
      ],
      toolbar: const AdminConsoleToolbar(
        searchHint: 'Search services, queues, storage, or integration dependencies',
        tabs: ['Overview', 'Dependencies', 'Queues', 'Storage', 'Cron'],
        filters: ['Critical', 'Watch', 'Healthy', 'Jobs', 'Integrations'],
      ),
      child: AdminSplitWorkspace(
        left: AdminStatCard(
          title: 'Dependency map',
          subtitle: 'The backend health service should own labels, statuses, and severity.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AdminDetailRows(
                rows: [
                  AdminDetailItem(label: 'Database', value: 'Live health endpoint pending'),
                  AdminDetailItem(label: 'Redis / Valkey', value: 'Live health endpoint pending'),
                  AdminDetailItem(label: 'Firebase', value: 'Live health endpoint pending'),
                  AdminDetailItem(label: 'R2 storage', value: 'Live health endpoint pending'),
                  AdminDetailItem(label: 'Email / SMS / Push', value: 'Live health endpoint pending'),
                  AdminDetailItem(label: 'Cron / queues', value: 'Live health endpoint pending'),
                ],
              ),
              SizedBox(height: 18),
              AdminEmptyState(
                title: 'No platform health payload connected yet',
                description:
                    'This module should bind to one backend health contract for status, latency, last sync, error counts, and queue pressure.',
                actionLabel: 'Bind `/admin/system/health` before showing dependency health.',
              ),
            ],
          ),
        ),
        center: AdminStatCard(
          title: 'System health',
          subtitle: 'A live operator table for platform trust and incident visibility.',
          child: Column(
            children: const [
              AdminDataTable<_PlatformHealthRow>(
                columns: [
                  AdminDataTableColumn<_PlatformHealthRow>(label: 'Dependency', valueBuilder: _platformDependency),
                  AdminDataTableColumn<_PlatformHealthRow>(label: 'Status', valueBuilder: _platformStatus),
                  AdminDataTableColumn<_PlatformHealthRow>(label: 'Latency', valueBuilder: _platformLatency),
                  AdminDataTableColumn<_PlatformHealthRow>(label: 'Last sync', valueBuilder: _platformLastSync),
                ],
                rows: [],
              ),
              SizedBox(height: 16),
              AdminEmptyState(
                title: 'No live health checks available yet',
                description:
                    'Replace static percentages and health adjectives with backend-reported dependency state, queue load, and storage utilization.',
                actionLabel: 'Wire the platform health service and dependency probes.',
              ),
            ],
          ),
        ),
        right: AdminStatCard(
          title: 'Operational follow-up',
          subtitle: 'Platform should expose incident actions and queue drill-downs once endpoints exist.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ChecklistLine(label: 'Dependency-specific drill-down routes'),
              _ChecklistLine(label: 'Background job and queue detail views'),
              _ChecklistLine(label: 'Storage usage and retention dashboards'),
              _ChecklistLine(label: 'Incident export and escalation hooks'),
              _ChecklistLine(label: 'Version, release, and last deploy visibility'),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformHealthRow {
  const _PlatformHealthRow();
}

String _platformDependency(_PlatformHealthRow value) => '';
String _platformStatus(_PlatformHealthRow value) => '';
String _platformLatency(_PlatformHealthRow value) => '';
String _platformLastSync(_PlatformHealthRow value) => '';

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.circle, size: 8, color: AdminColors.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AdminTypography.small.copyWith(
                color: AdminColors.subtext,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
