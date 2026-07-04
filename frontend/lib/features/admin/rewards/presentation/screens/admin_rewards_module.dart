import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminRewardsModule extends StatelessWidget {
  const AdminRewardsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Business / Rewards',
      title: 'Reward rule and redemption engine',
      description:
          'Control earning rules, redemption rules, active campaigns, and points economics without leaking implementation complexity into other modules.',
      primaryAction: AdminActionItem(label: 'New reward rule', icon: Icons.stars_outlined),
      secondaryAction: AdminActionItem(label: 'Redemption settings', icon: Icons.tune_outlined),
      leftTitle: 'Rule library',
      leftSubtitle: 'Backend-owned pricing and reward controls surfaced for operators.',
      leftChild: Column(
        children: [
          AdminEntityCard(item: AdminEntityItem(title: 'Referral qualification reward', subtitle: 'Action-code driven earning rule', meta: 'approval required false', status: 'Active', color: AdminColors.success)),
          AdminEntityCard(item: AdminEntityItem(title: 'Service visit rewards', subtitle: 'Eligible on defined service types only', meta: 'watch benefit overlap', status: 'Active', color: AdminColors.secondary)),
          AdminEntityCard(item: AdminEntityItem(title: 'Festival campaign', subtitle: 'Temporary multiplier on selected branches', meta: 'expires in 9 days', status: 'Timed', color: AdminColors.warning)),
        ],
      ),
      rightTitle: 'Points performance',
      rightSubtitle: 'Economics, liability, and campaign health.',
      rightChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Earned this month', value: '184k pts', meta: 'up 12%', color: AdminColors.success)),
          AdminHealthRow(item: AdminHealthItem(label: 'Redeemed this month', value: '63k pts', meta: 'healthy pacing', color: AdminColors.rewards)),
          AdminHealthRow(item: AdminHealthItem(label: 'Rule conflicts', value: '1', meta: 'commercial review pending', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'Expired points', value: '8.2k', meta: 'monitor fairness messaging', color: AdminColors.danger)),
        ],
      ),
    );
  }
}
