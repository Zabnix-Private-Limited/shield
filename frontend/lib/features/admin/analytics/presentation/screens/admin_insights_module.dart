import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminInsightsModule extends StatelessWidget {
  const AdminInsightsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Analytics / Insights',
      title: 'Growth, retention, and compliance insights',
      description:
          'A visual command layer for customer growth, branch comparison, visits, referrals, membership retention, and document compliance.',
      primaryAction: const AdminActionItem(label: 'Open dashboard pack', icon: Icons.insights_outlined),
      secondaryAction: const AdminActionItem(label: 'Compare branches', icon: Icons.bar_chart_outlined),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: const [
          AdminChartCard(title: 'Customer growth', subtitle: 'Rolling growth by branch and acquisition source'),
          AdminChartCard(title: 'Retention health', subtitle: 'Renewal and reactivation performance'),
          AdminChartCard(title: 'Visit throughput', subtitle: 'Branch and provider execution view'),
          AdminChartCard(title: 'Referral conversion', subtitle: 'Top referrer and campaign performance'),
        ],
      ),
    );
  }
}
