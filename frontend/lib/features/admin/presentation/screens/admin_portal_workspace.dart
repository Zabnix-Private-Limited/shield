import 'package:flutter/material.dart';

import '../../agents/presentation/screens/admin_agents_module.dart';
import '../../analytics/presentation/screens/admin_insights_module.dart';
import '../../audit/presentation/screens/admin_audit_module.dart';
import '../../availability/presentation/screens/admin_availability_module.dart';
import '../../crm/presentation/screens/admin_crm_module.dart';
import '../../customers/presentation/screens/admin_customers_module.dart';
import '../../dashboard/presentation/screens/admin_dashboard_module.dart';
import '../../documents/presentation/screens/admin_documents_module.dart';
import '../../memberships/presentation/screens/admin_memberships_module.dart';
import '../../notifications/presentation/screens/admin_notifications_module.dart';
import '../../organization/presentation/screens/admin_branches_module.dart';
import '../../organization/presentation/screens/admin_employees_module.dart';
import '../../organization/presentation/screens/admin_roles_module.dart';
import '../../providers/presentation/screens/admin_providers_module.dart';
import '../../referrals/presentation/screens/admin_referrals_module.dart';
import '../../reports/presentation/screens/admin_reports_module.dart';
import '../../rewards/presentation/screens/admin_rewards_module.dart';
import '../../services/presentation/screens/admin_services_module.dart';
import '../../settings/presentation/screens/admin_platform_module.dart';
import '../../settings/presentation/screens/admin_settings_module.dart';
import '../../shared/exports.dart';
import '../../visits/presentation/screens/admin_visits_module.dart';
import '../../wallet/presentation/screens/admin_wallet_module.dart';
import '../../../portal/presentation/portal_role_data.dart';

class AdminPortalWorkspace extends StatelessWidget {
  const AdminPortalWorkspace({
    super.key,
    required this.portal,
    required this.section,
  });

  final PortalRoleData portal;
  final PortalSectionData section;

  @override
  Widget build(BuildContext context) {
    return switch (section.key) {
      'dashboard' => const AdminDashboardModule(),
      'customers' => const AdminCustomersModule(),
      'agents' => const AdminAgentsModule(),
      'crm' => const AdminCrmModule(),
      'visits' => const AdminVisitsModule(),
      'documents' => const AdminDocumentsModule(),
      'memberships' => const AdminMembershipsModule(),
      'wallet' => const AdminWalletModule(),
      'rewards' => const AdminRewardsModule(),
      'referrals' => const AdminReferralsModule(),
      'providers' => const AdminProvidersModule(),
      'services' => const AdminServicesModule(),
      'availability' => const AdminAvailabilityModule(),
      'branches' => const AdminBranchesModule(),
      'employees' => const AdminEmployeesModule(),
      'roles' => const AdminRolesModule(),
      'reports' => const AdminReportsModule(),
      'insights' => const AdminInsightsModule(),
      'audit' => const AdminAuditModule(),
      'notifications' => const AdminNotificationsModule(),
      'settings' => const AdminSettingsModule(),
      'platform' => const AdminPlatformModule(),
      _ => _FallbackModule(section: section),
    };
  }
}

class _FallbackModule extends StatelessWidget {
  const _FallbackModule({required this.section});

  final PortalSectionData section;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Admin / ${section.title}',
      title: section.title,
      description: section.summary,
      primaryAction: const AdminActionItem(
        label: 'Open dashboard',
        icon: Icons.dashboard_customize_outlined,
      ),
      secondaryAction: const AdminActionItem(
        label: 'Review navigation',
        icon: Icons.account_tree_outlined,
      ),
      child: AdminEmptyState(
        title: '${section.title} module is reserved',
        description:
            'This section key is registered in the admin IA but does not yet have a dedicated module renderer.',
        actionLabel: 'Use the shared admin module pattern',
      ),
    );
  }
}
