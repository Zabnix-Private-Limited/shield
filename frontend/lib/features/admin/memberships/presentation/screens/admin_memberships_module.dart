import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminMembershipsModule extends StatelessWidget {
  const AdminMembershipsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Business / Memberships',
      title: 'Membership plans and lifecycle controls',
      description:
          'Manage plan definitions, benefits, pricing posture, renewal pipelines, usage signals, and expiry pressure from one surface.',
      primaryAction: AdminActionItem(label: 'Create plan', icon: Icons.card_membership_outlined),
      secondaryAction: AdminActionItem(label: 'Review renewals', icon: Icons.autorenew_outlined),
      leftTitle: 'Plan library',
      leftSubtitle: 'Reusable membership products and commercial posture.',
      leftChild: Column(
        children: [
          AdminEntityCard(item: AdminEntityItem(title: 'SHIELD Gold Annual', subtitle: 'Joining fee Rs. 2,999 • credit eligible', meta: 'Most active plan', status: 'Primary', color: AdminColors.secondary)),
          AdminEntityCard(item: AdminEntityItem(title: 'SHIELD Family Plus', subtitle: 'Benefit-heavy family bundle', meta: 'Needs pricing review', status: 'Review', color: AdminColors.warning)),
          AdminEntityCard(item: AdminEntityItem(title: 'SHIELD Senior Care', subtitle: 'High retention, high support intensity', meta: 'Expiry spike next month', status: 'Watch', color: AdminColors.danger)),
        ],
      ),
      rightTitle: 'Renewal and usage signals',
      rightSubtitle: 'Plans only matter when lifecycle pressure is visible.',
      rightChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Expiring in 7 days', value: '76', meta: 'renewal pipeline open', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'Renewed this month', value: '418', meta: '83% completion rate', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Dormant high-value members', value: '29', meta: 'target retention campaign', color: AdminColors.rewards)),
          AdminHealthRow(item: AdminHealthItem(label: 'Card issuance blocked', value: '11', meta: 'document or approval dependency', color: AdminColors.danger)),
        ],
      ),
    );
  }
}
