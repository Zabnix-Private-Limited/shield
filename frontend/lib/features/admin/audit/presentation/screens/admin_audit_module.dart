import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminAuditModule extends StatelessWidget {
  const AdminAuditModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Analytics / Audit logs',
      title: 'Audit, security, and change history',
      description:
          'Every important operational, auth, and configuration action needs a readable history with actor, time, reason, and target.',
      primaryAction: AdminActionItem(label: 'Export audit', icon: Icons.file_download_outlined),
      secondaryAction: AdminActionItem(label: 'Security view', icon: Icons.security_outlined),
      leftTitle: 'Activity and security feed',
      leftSubtitle: 'One place for approvals, auth, and high-risk actions.',
      leftChild: AdminTimeline(
        items: [
          AdminTimelineItem(time: '09:41', title: 'Rahul approved document', description: 'Customer SH-10284 Aadhaar verified.', accent: AdminColors.success),
          AdminTimelineItem(time: '09:46', title: 'Arjun added customer', description: 'New registration from Calicut North.', accent: AdminColors.secondary),
          AdminTimelineItem(time: '09:47', title: 'System wallet update', description: 'Pricing engine posted reward redemption audit.', accent: AdminColors.rewards),
          AdminTimelineItem(time: '10:02', title: 'Admin revoked session', description: 'Manual security reset for unusual login behavior.', accent: AdminColors.danger),
        ],
      ),
      rightTitle: 'Audit filters',
      rightSubtitle: 'Slice by actor, entity, action, severity, or branch.',
      rightChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Auth events', value: '426', meta: 'today', color: AdminColors.secondary)),
          AdminHealthRow(item: AdminHealthItem(label: 'Approval actions', value: '89', meta: 'documents, membership, wallet', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Configuration changes', value: '7', meta: 'roles, settings, commercial controls', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'Critical security events', value: '1', meta: 'immediate review required', color: AdminColors.danger)),
        ],
      ),
    );
  }
}
