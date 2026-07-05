import 'package:flutter/material.dart';

import '../registry/admin_platform_runtime.dart';
import '../registry/admin_workspace_catalog.dart';
import '../../shared/exports.dart';
import '../../../portal/presentation/portal_role_data.dart';

class AdminPortalWorkspace extends StatelessWidget {
  const AdminPortalWorkspace({
    super.key,
    required this.portal,
    required this.section,
    this.runtime,
  });

  final PortalRoleData portal;
  final PortalSectionData section;
  final AdminPlatformRuntime? runtime;

  @override
  Widget build(BuildContext context) {
    return _AdminRegisteredWorkspace(
      runtime: runtime ?? AdminWorkspaceCatalog.runtime,
      section: section,
    );
  }
}

class _AdminRegisteredWorkspace extends StatefulWidget {
  const _AdminRegisteredWorkspace({
    required this.runtime,
    required this.section,
  });

  final AdminPlatformRuntime runtime;
  final PortalSectionData section;

  @override
  State<_AdminRegisteredWorkspace> createState() =>
      _AdminRegisteredWorkspaceState();
}

class _AdminRegisteredWorkspaceState extends State<_AdminRegisteredWorkspace> {
  late AdminWorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.runtime.createWorkspaceController();
    _loadWorkspace();
  }

  @override
  void didUpdateWidget(covariant _AdminRegisteredWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime ||
        oldWidget.section.key != widget.section.key) {
      _controller.dispose();
      _controller = widget.runtime.createWorkspaceController();
      _loadWorkspace();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadWorkspace() {
    Future<void>.microtask(
      () => _controller.loadWorkspace(widget.section.key),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registration = widget.runtime.registrationFor(widget.section.key);
    if (registration == null) {
      return _FallbackModule(section: widget.section);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final snapshot = _controller.snapshot;
        switch (_controller.state.status) {
          case AdminWorkspaceStatus.loading:
            if (snapshot != null) {
              return registration.builder(context, snapshot);
            }
            return const AdminLoading();
          case AdminWorkspaceStatus.refreshing:
          case AdminWorkspaceStatus.ready:
            if (snapshot == null) {
              return const AdminLoading();
            }
            return registration.builder(context, snapshot);
          case AdminWorkspaceStatus.permissionDenied:
            return _PermissionDeniedModule(
              section: widget.section,
              message:
                  _controller.state.message ??
                  'This workspace requires an additional permission grant.',
            );
          case AdminWorkspaceStatus.error:
            return _ErrorModule(
              section: widget.section,
              message:
                  _controller.state.message ??
                  'Workspace runtime failed to load.',
            );
          case AdminWorkspaceStatus.empty:
          case AdminWorkspaceStatus.offline:
            return _FallbackModule(section: widget.section);
        }
      },
    );
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

class _PermissionDeniedModule extends StatelessWidget {
  const _PermissionDeniedModule({
    required this.section,
    required this.message,
  });

  final PortalSectionData section;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Admin / ${section.title}',
      title: section.title,
      description: section.summary,
      child: AdminEmptyState(
        title: 'Permission required',
        description: message,
        actionLabel: 'Grant the backend permission contract to unlock this workspace.',
      ),
    );
  }
}

class _ErrorModule extends StatelessWidget {
  const _ErrorModule({
    required this.section,
    required this.message,
  });

  final PortalSectionData section;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Admin / ${section.title}',
      title: section.title,
      description: section.summary,
      child: AdminEmptyState(
        title: 'Workspace runtime failed',
        description: message,
        actionLabel: 'Check workspace registration, schema ownership, and backend data contracts.',
      ),
    );
  }
}
