import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminNotificationsModule extends StatelessWidget {
  const AdminNotificationsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'System / Notifications',
      title: 'Notification operations inbox',
      description:
          'Internal notifications, delivery health, drafts, broadcasts, and scheduled campaigns should live in one message operations center.',
      primaryAction: AdminActionItem(label: 'Create broadcast', icon: Icons.campaign_outlined),
      secondaryAction: AdminActionItem(label: 'Schedule notification', icon: Icons.schedule_send_outlined),
      leftTitle: 'Inbox',
      leftSubtitle: 'Today, yesterday, and earlier grouped operational messages.',
      leftChild: Column(
        children: [
          AdminQueueTile(title: 'Verification backlog reminder', subtitle: 'Central ops broadcast to document team', status: 'Unread', color: AdminColors.warning),
          AdminQueueTile(title: 'Provider capacity alert', subtitle: 'Calicut North scheduling heads-up', status: 'Actioned', color: AdminColors.secondary),
          AdminQueueTile(title: 'Renewal campaign sent', subtitle: '76 expiring customers targeted', status: 'Delivered', color: AdminColors.success),
        ],
      ),
      rightTitle: 'Delivery health',
      rightSubtitle: 'Operational confidence for outbound communication.',
      rightChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Sent today', value: '1,842', meta: 'push + in-app', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Scheduled', value: '12', meta: 'next 72 hours', color: AdminColors.secondary)),
          AdminHealthRow(item: AdminHealthItem(label: 'Failed', value: '18', meta: 'device or payload issues', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'Suppressed', value: '3', meta: 'policy or duplication guard', color: AdminColors.danger)),
        ],
      ),
    );
  }
}
