import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminSettingsModule extends StatelessWidget {
  const AdminSettingsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminConsolePage(
      title: 'Settings',
      subtitle:
          'Server-backed organization, security, integration, and platform configuration should open directly into editable admin controls instead of navigation tiles.',
      actions: const [
        AdminActionItem(label: 'Review access', icon: Icons.lock_outline),
        AdminActionItem(label: 'Save changes', icon: Icons.save_outlined),
      ],
      toolbar: const AdminConsoleToolbar(
        searchHint: 'Search settings, policies, and integrations',
        filters: [
          'Company',
          'Authentication',
          'Branding',
          'Notifications',
          'Storage',
          'Feature flags',
        ],
      ),
      child: AdminSplitWorkspace(
        left: AdminStatCard(
          title: 'Configuration areas',
          subtitle: 'The backend should own this registry and permission map.',
          child: Column(
            children: const [
              _SettingsAreaTile(
                icon: Icons.business_outlined,
                title: 'Company',
                subtitle: 'Identity, compliance, timezone, language, and contacts',
              ),
              _SettingsAreaTile(
                icon: Icons.shield_outlined,
                title: 'Security',
                subtitle: 'Sessions, passwordless policy, revoke defaults, and access rules',
              ),
              _SettingsAreaTile(
                icon: Icons.palette_outlined,
                title: 'Branding',
                subtitle: 'Logos, themes, white-label assets, and communication identity',
              ),
              _SettingsAreaTile(
                icon: Icons.api_outlined,
                title: 'Integrations',
                subtitle: 'API keys, webhooks, storage credentials, and provider connections',
              ),
              _SettingsAreaTile(
                icon: Icons.flag_outlined,
                title: 'Feature flags',
                subtitle: 'Rollout switches, tenant-scoped release gates, and visibility controls',
              ),
            ],
          ),
        ),
        center: AdminDetailPanel(
          title: 'Company configuration',
          subtitle: 'Live values should arrive from `/admin/settings/company` and related settings endpoints.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AdminDetailRows(
                rows: [
                  AdminDetailItem(label: 'Registered name', value: 'Pending backend contract'),
                  AdminDetailItem(label: 'GST / PAN', value: 'Pending backend contract'),
                  AdminDetailItem(label: 'Support email', value: 'Pending backend contract'),
                  AdminDetailItem(label: 'Timezone', value: 'Pending backend contract'),
                  AdminDetailItem(label: 'Language', value: 'Pending backend contract'),
                  AdminDetailItem(label: 'Country', value: 'Pending backend contract'),
                ],
              ),
              SizedBox(height: 18),
              AdminEmptyState(
                title: 'No live settings payload connected yet',
                description:
                    'Settings v2 should bind each section to explicit GET and PATCH contracts instead of hardcoded navigation cards.',
                actionLabel: 'Wire company, security, branding, storage, and feature flag endpoints.',
              ),
            ],
          ),
        ),
        right: AdminStatCard(
          title: 'Implementation contract',
          subtitle: 'What this module should own once the backend workspace registry is live.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ChecklistLine(label: 'Server-owned section registry and permissions'),
              _ChecklistLine(label: 'Editable form sections with validation states'),
              _ChecklistLine(label: 'Scoped save actions and optimistic refresh'),
              _ChecklistLine(label: 'Audit trail for every configuration change'),
              _ChecklistLine(label: 'Environment-safe empty states when a setting is unavailable'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsAreaTile extends StatelessWidget {
  const _SettingsAreaTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.mutedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AdminColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AdminTypography.small.copyWith(
                    color: AdminColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AdminTypography.small.copyWith(
                    color: AdminColors.caption,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.check_circle_outline, size: 16, color: AdminColors.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AdminTypography.small.copyWith(
                color: AdminColors.subtext,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
