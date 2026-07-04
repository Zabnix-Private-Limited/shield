import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminSettingsModule extends StatelessWidget {
  const AdminSettingsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'System / Settings',
      title: 'Company, security, and platform settings',
      description:
          'Centralized operational configuration for company details, branding, notifications, security posture, API surfaces, storage, and feature controls.',
      primaryAction: const AdminActionItem(label: 'Save configuration', icon: Icons.save_outlined),
      secondaryAction: const AdminActionItem(label: 'Review security', icon: Icons.lock_outline),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: const [
          AdminSettingCard(title: 'Company', subtitle: 'Legal identity, support contacts, regional defaults', icon: Icons.business_outlined),
          AdminSettingCard(title: 'Branding', subtitle: 'Visual assets, logos, colors, and public-facing consistency', icon: Icons.palette_outlined),
          AdminSettingCard(title: 'Notifications', subtitle: 'templates, default channels, escalation rules', icon: Icons.notifications_active_outlined),
          AdminSettingCard(title: 'Security', subtitle: 'session policy, auth posture, revocation defaults', icon: Icons.security_outlined),
          AdminSettingCard(title: 'API', subtitle: 'integration credentials, outbound callbacks, access policy', icon: Icons.api_outlined),
          AdminSettingCard(title: 'Storage', subtitle: 'bucket usage, signed URL policy, file retention', icon: Icons.cloud_outlined),
          AdminSettingCard(title: 'Feature flags', subtitle: 'controlled rollout surfaces and operator toggles', icon: Icons.flag_outlined),
        ],
      ),
    );
  }
}
