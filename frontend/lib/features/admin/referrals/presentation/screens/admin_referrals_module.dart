import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminReferralsModule extends StatelessWidget {
  const AdminReferralsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Business / Referral network',
      title: 'Referral graph and conversion intelligence',
      description:
          'Track top referrers, pending rewards, qualification progression, campaign performance, and network growth in one growth workspace.',
      primaryAction: AdminActionItem(label: 'Launch campaign', icon: Icons.campaign_outlined),
      secondaryAction: AdminActionItem(label: 'Review rewards', icon: Icons.account_tree_outlined),
      leftTitle: 'Referral tree',
      leftSubtitle: 'A structured network view instead of a flat list.',
      leftChild: AdminTreeView(
        nodes: [
          AdminTreeNodeData(label: 'Arun Thomas', depth: 0, note: '14 referrals • 4 rewarded'),
          AdminTreeNodeData(label: 'Nisha B', depth: 1, note: 'Qualified'),
          AdminTreeNodeData(label: 'Vipin K', depth: 1, note: 'Pending first visit'),
          AdminTreeNodeData(label: 'Sneha R', depth: 2, note: 'Rewarded'),
          AdminTreeNodeData(label: 'Jabir P', depth: 1, note: 'Rejected'),
        ],
      ),
      rightTitle: 'Growth and reward signals',
      rightSubtitle: 'Where referral growth is compounding and where it is leaking.',
      rightChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Qualified this week', value: '62', meta: 'best from Kochi Central', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Pending qualification', value: '118', meta: 'watch visit completion dependency', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'Top referrer conversion', value: '34%', meta: 'Arun Thomas cluster', color: AdminColors.rewards)),
          AdminHealthRow(item: AdminHealthItem(label: 'Rejected chains', value: '9', meta: 'data quality or fraud review', color: AdminColors.danger)),
        ],
      ),
    );
  }
}
