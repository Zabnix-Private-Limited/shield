import 'package:flutter/material.dart';

import '../registry/admin_workspace_catalog.dart';
import '../../shared/exports.dart';
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
    return AdminWorkspaceCatalog.build(section.key) ??
        _FallbackModule(section: section);
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
