import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminProvidersModule extends StatelessWidget {
  const AdminProvidersModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Providers / Providers',
      title: 'Provider network workspace',
      description:
          'A complete provider CRM for profile, services, availability, bookings, reviews, documents, and timeline history.',
      primaryAction: const AdminActionItem(label: 'Add provider', icon: Icons.local_hospital_outlined),
      secondaryAction: const AdminActionItem(label: 'Map branch', icon: Icons.place_outlined),
      child: const Column(
        children: [
          AdminSectionTabs(tabs: ['Profile', 'Availability', 'Services', 'Bookings', 'Reviews', 'Documents', 'Timeline', 'Payments']),
          SizedBox(height: 16),
          AdminSplitWorkspace(
            left: _ProviderListPanel(),
            center: _ProviderWorkspacePanel(),
            right: _ProviderTimelinePanel(),
          ),
        ],
      ),
    );
  }
}

class _ProviderListPanel extends StatelessWidget {
  const _ProviderListPanel();

  @override
  Widget build(BuildContext context) {
    return const Panel(
      title: 'Provider list',
      subtitle: 'Find providers by type, branch mapping, and capacity risk.',
      child: Column(
        children: [
          AdminEntityCard(item: AdminEntityItem(title: 'Dr. Asha Menon', subtitle: 'Dermatology • Kochi Central', meta: '92% slot utilization', status: 'Healthy', color: AdminColors.success)),
          AdminEntityCard(item: AdminEntityItem(title: 'Lifeline Diagnostics', subtitle: 'Lab partner • Thrissur Hub', meta: 'document renewal due', status: 'Review', color: AdminColors.warning)),
          AdminEntityCard(item: AdminEntityItem(title: 'SmileCraft Dental', subtitle: 'Dental • Calicut North', meta: 'booking delays rising', status: 'Watch', color: AdminColors.danger)),
        ],
      ),
    );
  }
}

class _ProviderWorkspacePanel extends StatelessWidget {
  const _ProviderWorkspacePanel();

  @override
  Widget build(BuildContext context) {
    return const Panel(
      title: 'Provider workspace',
      subtitle: 'Profile, branch mapping, services, and booking pressure.',
      child: Column(
        children: [
          AdminIdentityHero(
            name: 'Dr. Asha Menon',
            code: 'PR-041',
            primaryMeta: 'Dermatology specialist',
            secondaryMeta: 'Kochi Central • Google-auth internal user • 3 active branch mappings',
            badges: ['Active', 'High demand', 'Documents valid'],
          ),
          SizedBox(height: 16),
          AdminKpiStrip(
            items: [
              AdminKpiItem(label: 'Bookings', value: '148', note: 'this month'),
              AdminKpiItem(label: 'Utilization', value: '92%', note: 'slot fill rate'),
              AdminKpiItem(label: 'Rating', value: '4.8', note: 'customer review avg'),
              AdminKpiItem(label: 'Pending docs', value: '1', note: 'renewal required'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderTimelinePanel extends StatelessWidget {
  const _ProviderTimelinePanel();

  @override
  Widget build(BuildContext context) {
    return const Panel(
      title: 'Timeline and health',
      subtitle: 'Provider changes, compliance, and booking quality.',
      child: AdminTimeline(
        items: [
          AdminTimelineItem(time: 'Today', title: 'Availability updated', description: 'Friday afternoon slots blocked for training.', accent: AdminColors.visits),
          AdminTimelineItem(time: 'Yesterday', title: 'Review surge', description: '12 positive care reviews after camp workflow.', accent: AdminColors.success),
          AdminTimelineItem(time: 'Jun 30', title: 'Document renewal requested', description: 'Registration file expires in 6 days.', accent: AdminColors.warning),
        ],
      ),
    );
  }
}
