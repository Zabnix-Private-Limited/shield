import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminAgentsModule extends StatelessWidget {
  const AdminAgentsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Operations / Agents',
      title: 'Agent performance and assignment center',
      description:
          'Manage branch assignment, territory health, customers, follow-ups, visits, and field productivity without leaving one workspace.',
      primaryAction: const AdminActionItem(label: 'Add agent', icon: Icons.badge_outlined),
      secondaryAction: const AdminActionItem(label: 'Assign branch', icon: Icons.place_outlined),
      child: const Column(
        children: [
          AdminSectionTabs(
            tabs: ['Overview', 'Customers', 'Performance', 'Follow-Ups', 'Visits', 'Attendance', 'Documents', 'Timeline'],
          ),
          SizedBox(height: 16),
          AdminSplitWorkspace(
            left: _AgentListPanel(),
            center: _AgentWorkspacePanel(),
            right: _AgentTimelinePanel(),
          ),
        ],
      ),
    );
  }
}

class _AgentListPanel extends StatelessWidget {
  const _AgentListPanel();

  @override
  Widget build(BuildContext context) {
    return AdminStatCard(
      title: 'Agent list',
      subtitle: 'Sort by region, performance, SLA risk, and active network.',
      child: Column(
        children: const [
          AdminEntityCard(item: AdminEntityItem(title: 'Rahul Das', subtitle: 'Kochi Central • 428 customers', meta: 'Top conversion this month', status: 'High performer', color: AdminColors.success)),
          AdminEntityCard(item: AdminEntityItem(title: 'Meera S', subtitle: 'Calicut North • 311 customers', meta: '7 overdue follow-ups', status: 'Needs support', color: AdminColors.warning)),
          AdminEntityCard(item: AdminEntityItem(title: 'Nithin Paul', subtitle: 'Trivandrum City • 288 customers', meta: 'visit completion down this week', status: 'Watch', color: AdminColors.danger)),
        ],
      ),
    );
  }
}

class _AgentWorkspacePanel extends StatelessWidget {
  const _AgentWorkspacePanel();

  @override
  Widget build(BuildContext context) {
    return AdminDetailPanel(
      title: 'Agent workspace',
      subtitle: 'Identity, branch, territory, and KPI context in one place.',
      child: Column(
        children: const [
          AdminIdentityHero(
            name: 'Rahul Das',
            code: 'AG-0012',
            primaryMeta: 'Primary branch Kochi Central',
            secondaryMeta: 'South urban territory • Google-auth internal profile',
            badges: ['Active', 'Primary assignee', 'Field leader'],
          ),
          SizedBox(height: 16),
          AdminKpiStrip(
            items: [
              AdminKpiItem(label: 'Customers', value: '428', note: 'active network'),
              AdminKpiItem(label: 'Follow-ups', value: '96%', note: 'completed on time'),
              AdminKpiItem(label: 'Visits', value: '124', note: 'this month'),
              AdminKpiItem(label: 'Retention', value: '91%', note: 'rolling 30 days'),
            ],
          ),
          SizedBox(height: 16),
          AdminDetailRows(
            rows: [
              AdminDetailItem(label: 'Branch mapping', value: 'Kochi Central, backup Ernakulam South'),
              AdminDetailItem(label: 'Working mode', value: 'Field-heavy, morning-first onboarding'),
              AdminDetailItem(label: 'Current escalation', value: '7 pending callbacks over SLA'),
              AdminDetailItem(label: 'Last attendance sync', value: '2026-07-03 08:31'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgentTimelinePanel extends StatelessWidget {
  const _AgentTimelinePanel();

  @override
  Widget build(BuildContext context) {
    return AdminStatCard(
      title: 'Timeline and alerts',
      subtitle: 'Who changed what, where agent performance is moving, and which customers are at risk.',
      child: const AdminTimeline(
        items: [
          AdminTimelineItem(time: '09:20', title: 'New customer approved', description: 'Two onboarding profiles cleared after admin review.', accent: AdminColors.success),
          AdminTimelineItem(time: 'Yesterday', title: 'Visit created', description: 'Scheduled 6 care visits across dermatology and lab.', accent: AdminColors.visits),
          AdminTimelineItem(time: 'Yesterday', title: 'Document backlog flagged', description: '3 uploaded KYC packets still missing verification.', accent: AdminColors.warning),
          AdminTimelineItem(time: 'Jun 30', title: 'Branch transfer requested', description: 'Temporary support request for Ernakulam South workload.', accent: AdminColors.secondary),
        ],
      ),
    );
  }
}
