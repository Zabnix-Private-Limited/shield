import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminBranchesModule extends StatelessWidget {
  const AdminBranchesModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Organization / Branches',
      title: 'Branch performance workspace',
      description:
          'Compare operational throughput, customer growth, provider health, visit density, and staff load branch by branch.',
      primaryAction: const AdminActionItem(label: 'Add branch', icon: Icons.apartment_outlined),
      secondaryAction: const AdminActionItem(label: 'Compare branches', icon: Icons.compare_arrows_outlined),
      child: const Column(
        children: [
          AdminSectionTabs(tabs: ['Overview', 'Performance', 'Employees', 'Providers', 'Customers', 'Reports']),
          SizedBox(height: 16),
          AdminSplitWorkspace(
            left: _BranchListPanel(),
            center: _BranchWorkspacePanel(),
            right: _BranchTimelinePanel(),
          ),
        ],
      ),
    );
  }
}

class _BranchListPanel extends StatelessWidget {
  const _BranchListPanel();

  @override
  Widget build(BuildContext context) {
    return const Panel(
      title: 'Branch list',
      subtitle: 'Health and load across the active network.',
      child: Column(
        children: [
          AdminEntityCard(item: AdminEntityItem(title: 'Kochi Central', subtitle: 'largest active customer base', meta: 'verification and follow-up health strong', status: 'Strong', color: AdminColors.success)),
          AdminEntityCard(item: AdminEntityItem(title: 'Calicut North', subtitle: 'capacity and documents under stress', meta: 'provider-side attention needed', status: 'Watch', color: AdminColors.danger)),
          AdminEntityCard(item: AdminEntityItem(title: 'Thrissur Hub', subtitle: 'best referral conversion this month', meta: 'stable ops', status: 'Healthy', color: AdminColors.rewards)),
        ],
      ),
    );
  }
}

class _BranchWorkspacePanel extends StatelessWidget {
  const _BranchWorkspacePanel();

  @override
  Widget build(BuildContext context) {
    return const Panel(
      title: 'Branch workspace',
      subtitle: 'Staff, providers, customers, and performance without switching modules.',
      child: Column(
        children: [
          AdminIdentityHero(
            name: 'Kochi Central',
            code: 'BR-001',
            primaryMeta: 'Primary urban branch',
            secondaryMeta: '4820 active customers • 18 providers • 12 internal users',
            badges: ['High growth', 'Healthy verification', 'Top revenue'],
          ),
          SizedBox(height: 16),
          AdminKpiStrip(
            items: [
              AdminKpiItem(label: 'Customers', value: '4,820', note: 'active'),
              AdminKpiItem(label: 'Visits', value: '76', note: 'today'),
              AdminKpiItem(label: 'Providers', value: '18', note: 'active'),
              AdminKpiItem(label: 'Follow-up SLA', value: '94%', note: 'healthy'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchTimelinePanel extends StatelessWidget {
  const _BranchTimelinePanel();

  @override
  Widget build(BuildContext context) {
    return const Panel(
      title: 'Operational signals',
      subtitle: 'The branch-level activity and risk story.',
      child: AdminTimeline(
        items: [
          AdminTimelineItem(time: 'Today', title: 'Membership renewal campaign launched', description: '76 expiring members targeted.', accent: AdminColors.secondary),
          AdminTimelineItem(time: 'Yesterday', title: 'Provider document verified', description: 'Lab partner compliance restored.', accent: AdminColors.success),
          AdminTimelineItem(time: 'Jun 30', title: 'Follow-up backlog cleared', description: 'SLA recovered after two-day surge.', accent: AdminColors.warning),
        ],
      ),
    );
  }
}
