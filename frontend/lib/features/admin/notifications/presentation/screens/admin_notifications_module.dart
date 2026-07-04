import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminNotificationsModule extends StatelessWidget {
  const AdminNotificationsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminConsolePage(
      title: 'Notifications',
      subtitle:
          'This module should manage templates, broadcasts, queues, and delivery telemetry as real operational data instead of a fake inbox.',
      actions: const [
        AdminActionItem(label: 'Schedule broadcast', icon: Icons.schedule_send_outlined),
        AdminActionItem(label: 'Create broadcast', icon: Icons.campaign_outlined),
      ],
      toolbar: const AdminConsoleToolbar(
        searchHint: 'Search messages, templates, recipients, and queue events',
        tabs: [
          'Templates',
          'Broadcasts',
          'Campaigns',
          'Delivery logs',
          'Push queue',
        ],
        filters: [
          'Draft',
          'Scheduled',
          'Running',
          'Delivered',
          'Failed',
        ],
      ),
      child: AdminSplitWorkspace(
        left: AdminStatCard(
          title: 'Channel registry',
          subtitle: 'Backend-owned surfaces and transport health should render here.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AdminDetailRows(
                rows: [
                  AdminDetailItem(label: 'Push', value: 'Awaiting live queue telemetry'),
                  AdminDetailItem(label: 'Email', value: 'Awaiting live queue telemetry'),
                  AdminDetailItem(label: 'SMS', value: 'Awaiting live queue telemetry'),
                  AdminDetailItem(label: 'WhatsApp', value: 'Awaiting live queue telemetry'),
                  AdminDetailItem(label: 'Webhook', value: 'Awaiting live queue telemetry'),
                ],
              ),
              SizedBox(height: 18),
              AdminEmptyState(
                title: 'No channel telemetry connected yet',
                description:
                    'Replace static delivery summary cards with live transport health, retry backlog, and suppression signals.',
                actionLabel: 'Bind `/notifications/logs`, `/notifications/queue`, and channel status endpoints.',
              ),
            ],
          ),
        ),
        center: AdminStatCard(
          title: 'Broadcasts',
          subtitle: 'Primary workspace for outbound campaigns and scheduled communication.',
          child: Column(
            children: const [
              AdminDataTable<_NotificationBroadcastRow>(
                columns: [
                  AdminDataTableColumn<_NotificationBroadcastRow>(label: 'Title', valueBuilder: _broadcastTitle),
                  AdminDataTableColumn<_NotificationBroadcastRow>(label: 'Audience', valueBuilder: _broadcastAudience),
                  AdminDataTableColumn<_NotificationBroadcastRow>(label: 'Status', valueBuilder: _broadcastStatus),
                  AdminDataTableColumn<_NotificationBroadcastRow>(label: 'Scheduled', valueBuilder: _broadcastScheduled),
                ],
                rows: [],
              ),
              SizedBox(height: 16),
              AdminEmptyState(
                title: 'No broadcast dataset connected yet',
                description:
                    'The final screen should be table-driven with pagination, audience targeting, approvals, and retryable delivery workflows.',
                actionLabel: 'Bind `/notifications/broadcasts` before enabling creation and editing flows.',
              ),
            ],
          ),
        ),
        right: AdminStatCard(
          title: 'Delivery logs',
          subtitle: 'Per-recipient delivery evidence should replace summary cards and fake health metrics.',
          child: Column(
            children: const [
              AdminDataTable<_NotificationLogRow>(
                columns: [
                  AdminDataTableColumn<_NotificationLogRow>(label: 'Message', valueBuilder: _logMessage),
                  AdminDataTableColumn<_NotificationLogRow>(label: 'Channel', valueBuilder: _logChannel),
                  AdminDataTableColumn<_NotificationLogRow>(label: 'Status', valueBuilder: _logStatus),
                ],
                rows: [],
              ),
              SizedBox(height: 16),
              AdminEmptyState(
                title: 'No delivery events available yet',
                description:
                    'Delivery logs should expose recipient status, opened and clicked evidence, failure reasons, and retry actions.',
                actionLabel: 'Bind `/notifications/logs` and `/notifications/queue` for live operational visibility.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBroadcastRow {
  const _NotificationBroadcastRow();
}

String _broadcastTitle(_NotificationBroadcastRow value) => '';
String _broadcastAudience(_NotificationBroadcastRow value) => '';
String _broadcastStatus(_NotificationBroadcastRow value) => '';
String _broadcastScheduled(_NotificationBroadcastRow value) => '';

class _NotificationLogRow {
  const _NotificationLogRow();
}

String _logMessage(_NotificationLogRow value) => '';
String _logChannel(_NotificationLogRow value) => '';
String _logStatus(_NotificationLogRow value) => '';
