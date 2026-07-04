import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminRolesModule extends StatelessWidget {
  const AdminRolesModule({super.key});

  @override
  Widget build(BuildContext context) {
    return const TwoPanelModule(
      eyebrow: 'Organization / Roles',
      title: 'Role catalog and permission matrix',
      description:
          'A governance surface for backend-authoritative roles, permissions, scopes, and assignment safety.',
      primaryAction: AdminActionItem(label: 'Add role', icon: Icons.admin_panel_settings_outlined),
      secondaryAction: AdminActionItem(label: 'Review matrix', icon: Icons.grid_view_outlined),
      leftTitle: 'Role catalog',
      leftSubtitle: 'Frontend shell labels must stay secondary to backend RBAC truth.',
      leftChild: Column(
        children: [
          AdminEntityCard(item: AdminEntityItem(title: 'ADMIN', subtitle: 'Global unrestricted platform governance', meta: 'system role', status: 'Critical', color: AdminColors.danger)),
          AdminEntityCard(item: AdminEntityItem(title: 'SHIELD_AGENT', subtitle: 'Field onboarding, follow-up, visit orchestration', meta: 'branch scoped', status: 'Operational', color: AdminColors.secondary)),
          AdminEntityCard(item: AdminEntityItem(title: 'CRM_EXECUTIVE', subtitle: 'Retention and complaint workflows', meta: 'assigned-customer scoped', status: 'Operational', color: AdminColors.success)),
        ],
      ),
      rightTitle: 'Permission matrix',
      rightSubtitle: 'A compact representation of module ownership and access pressure.',
      rightChild: AdminPermissionMatrix(),
    );
  }
}
