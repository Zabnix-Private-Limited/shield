import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminWalletModule extends StatelessWidget {
  const AdminWalletModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Business / Wallet',
      title: 'Wallet and ledger operations',
      description:
          'A Stripe-like operational surface for transactions, recharges, adjustments, rewards, and audit-safe ledger visibility.',
      primaryAction: AdminActionItem(label: 'Post adjustment', icon: Icons.account_balance_wallet_outlined),
      secondaryAction: AdminActionItem(label: 'Review audits', icon: Icons.receipt_long_outlined),
      leftTitle: 'Ledger overview',
      leftSubtitle: 'Wallet health across cash, rewards, and hidden commercial benefit behavior.',
      leftChild: Column(
        children: [
          AdminHealthRow(item: AdminHealthItem(label: 'Cash ledger volume', value: 'Rs. 12.8L', meta: 'rolling 7 days', color: AdminColors.secondary)),
          AdminHealthRow(item: AdminHealthItem(label: 'Reward points issued', value: '84.3k', meta: 'qualified and approved', color: AdminColors.rewards)),
          AdminHealthRow(item: AdminHealthItem(label: 'Manual adjustments', value: '13', meta: 'today', color: AdminColors.warning)),
          AdminHealthRow(item: AdminHealthItem(label: 'Pricing audit outliers', value: '2', meta: 'need review', color: AdminColors.danger)),
        ],
      ),
      rightTitle: 'Recent transaction rail',
      rightSubtitle: 'Operational events worth reviewing before finance drift grows.',
      rightChild: AdminTimeline(
        items: [
          AdminTimelineItem(time: '09:49', title: 'Manual recharge approved', description: 'Rs. 1,000 posted to SH-10284 after central review.', accent: AdminColors.success),
          AdminTimelineItem(time: '09:52', title: 'Reward redemption applied', description: '2,500 points converted under current redemption rule.', accent: AdminColors.rewards),
          AdminTimelineItem(time: '10:04', title: 'Adjustment flagged', description: 'Mismatch between expected discount and final payable.', accent: AdminColors.danger),
        ],
      ),
    );
  }
}
