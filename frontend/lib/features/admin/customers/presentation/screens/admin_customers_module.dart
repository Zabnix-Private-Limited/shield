import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminCustomersModule extends StatelessWidget {
  const AdminCustomersModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Operations / Customers',
      title: 'Customer control workspace',
      description:
          'A master-detail CRM for customer identity, timeline, wallet, membership, visits, documents, referrals, and audit visibility.',
      primaryAction: const AdminActionItem(
        label: 'Create customer',
        icon: Icons.person_add_alt_1_outlined,
      ),
      secondaryAction: const AdminActionItem(
        label: 'Advanced filters',
        icon: Icons.tune_outlined,
      ),
      child: const Column(
        children: [
          AdminToolbar(
            searchHint: 'Search customers, IDs, branches, agents, providers',
            filters: ['Active', 'Pending docs', 'Today visits', 'Expiring membership'],
          ),
          SizedBox(height: 16),
          AdminSectionTabs(
            tabs: [
              'Overview',
              'Timeline',
              'Tasks',
              'Documents',
              'Visits',
              'Wallet',
              'Membership',
              'Medical',
              'Referrals',
              'Notes',
              'Activity Log',
            ],
          ),
          SizedBox(height: 16),
          AdminSplitWorkspace(
            left: _CustomerListPanel(),
            center: _CustomerWorkspacePanel(),
            right: _CustomerTimelinePanel(),
          ),
        ],
      ),
    );
  }
}

class _CustomerListPanel extends StatelessWidget {
  const _CustomerListPanel();

  @override
  Widget build(BuildContext context) {
    return AdminStatCard(
      title: 'Customer list',
      subtitle: 'Global search, branch filters, lifecycle status, and priority queues.',
      child: Column(
        children: const [
          AdminEntityCard(
            item: AdminEntityItem(
              title: 'Arun Thomas',
              subtitle: 'ID SH-10284 • Gold member • Kochi Central',
              meta: 'Pending visit today',
              status: 'Priority',
              color: AdminColors.warning,
            ),
          ),
          AdminEntityCard(
            item: AdminEntityItem(
              title: 'Lakshmi Nair',
              subtitle: 'ID SH-09921 • Verification complete • Thrissur Hub',
              meta: 'Wallet recharge yesterday',
              status: 'Healthy',
              color: AdminColors.success,
            ),
          ),
          AdminEntityCard(
            item: AdminEntityItem(
              title: 'Fathima Rahman',
              subtitle: 'ID SH-10602 • Documents pending • Calicut North',
              meta: 'Follow-up overdue',
              status: 'Escalate',
              color: AdminColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerWorkspacePanel extends StatelessWidget {
  const _CustomerWorkspacePanel();

  @override
  Widget build(BuildContext context) {
    return AdminDetailPanel(
      title: 'Customer workspace',
      subtitle:
          'Profile, membership, wallet, provider, branch, and next-step visibility.',
      child: Column(
        children: const [
          AdminIdentityHero(
            name: 'Arun Thomas',
            code: 'SH-10284',
            primaryMeta: 'Member since 2025-11-12',
            secondaryMeta:
                'Kochi Central • +91 98XXXXXX12 • Assigned to Rahul Das',
            badges: ['Gold member', 'Wallet active', 'Visit today'],
          ),
          SizedBox(height: 16),
          AdminKpiStrip(
            items: [
              AdminKpiItem(label: 'Wallet', value: 'Rs. 4,820', note: 'cash + rewards'),
              AdminKpiItem(label: 'Next visit', value: '10:30 AM', note: 'Dermatology'),
              AdminKpiItem(label: 'Documents', value: '6 / 7', note: 'one pending'),
              AdminKpiItem(label: 'Referrals', value: '14', note: '4 rewarded'),
            ],
          ),
          SizedBox(height: 16),
          AdminDetailRows(
            rows: [
              AdminDetailItem(label: 'Membership', value: 'SHIELD Gold Annual'),
              AdminDetailItem(label: 'Branch', value: 'Kochi Central'),
              AdminDetailItem(label: 'Primary provider', value: 'Dr. Asha Menon'),
              AdminDetailItem(label: 'Last wallet adjustment', value: '2026-07-02 18:22'),
              AdminDetailItem(label: 'Current risk', value: 'Pending follow-up on lab review'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerTimelinePanel extends StatelessWidget {
  const _CustomerTimelinePanel();

  @override
  Widget build(BuildContext context) {
    return AdminStatCard(
      title: 'Customer timeline',
      subtitle: 'The customer story should be the hero, not a buried tab.',
      child: const AdminTimeline(
        items: [
          AdminTimelineItem(
            time: 'Today',
            title: 'Visit scheduled',
            description: '10:30 AM dermatology consult with branch-level slot lock.',
            accent: AdminColors.visits,
          ),
          AdminTimelineItem(
            time: 'Yesterday',
            title: 'Aadhaar uploaded',
            description: 'Verification metadata attached and queued for review.',
            accent: AdminColors.warning,
          ),
          AdminTimelineItem(
            time: 'Yesterday',
            title: 'Follow-up completed',
            description: 'Call outcome captured with prescription note.',
            accent: AdminColors.success,
          ),
          AdminTimelineItem(
            time: 'Jun 29',
            title: 'Registered',
            description: 'Agent-led onboarding at Kochi Central.',
            accent: AdminColors.secondary,
          ),
          AdminTimelineItem(
            time: 'Jun 28',
            title: 'Wallet credited',
            description: 'Promotional recharge posted with pricing audit entry.',
            accent: AdminColors.rewards,
          ),
        ],
      ),
    );
  }
}
