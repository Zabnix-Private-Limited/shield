import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  bool _syncingRouteState = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.runtime.createWorkspaceController();
    _controller.addListener(_handleControllerChanged);
    _loadWorkspace();
  }

  @override
  void didUpdateWidget(covariant _AdminRegisteredWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime ||
        oldWidget.section.key != widget.section.key) {
      _controller.removeListener(_handleControllerChanged);
      _controller.dispose();
      _controller = widget.runtime.createWorkspaceController();
      _controller.addListener(_handleControllerChanged);
      _loadWorkspace();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _loadWorkspace() {
    Future<void>.microtask(
      () => _controller.loadWorkspace(
        widget.section.key,
        query: _queryFromRoute(),
      ),
    );
  }

  AdminWorkspaceQuery _queryFromRoute() {
    final uri = _currentUriOrNull(context);
    final queryParameters = uri?.queryParameters ?? const <String, String>{};
    return AdminWorkspaceQuery(
      search: _readOptionalQuery(queryParameters, 'search'),
      status: _readOptionalQuery(queryParameters, 'status'),
      tab: _readOptionalQuery(queryParameters, 'tab'),
      selectedId: _readOptionalQuery(queryParameters, 'selected_id'),
      sortKey: _readOptionalQuery(queryParameters, 'sort_key'),
      sortDirection: _readOptionalQuery(queryParameters, 'sort_direction'),
      page: _readPositiveInt(queryParameters['page']) ?? 1,
      pageSize: _readPositiveInt(queryParameters['page_size']) ?? 25,
    );
  }

  void _handleControllerChanged() {
    if (!mounted || _syncingRouteState) {
      return;
    }

    final currentUri = _currentUriOrNull(context);
    if (currentUri == null) {
      return;
    }
    final nextQuery = _controller.query.toQueryParameters().map(
      (key, value) => MapEntry(key, value.toString()),
    );

    if (_mapsEqual(currentUri.queryParameters, nextQuery)) {
      return;
    }

    _syncingRouteState = true;
    final nextUri = currentUri.replace(
      queryParameters: nextQuery.isEmpty ? null : nextQuery,
    );
    context.replace(nextUri.toString());
    _syncingRouteState = false;
  }

  @override
  Widget build(BuildContext context) {
    final registration = widget.runtime.registrationFor(widget.section.key);
    if (registration == null) {
      return _ErrorModule(
        section: widget.section,
        message:
            'Workspace "${widget.section.key}" is not registered in the admin runtime.',
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final snapshot = _controller.snapshot;
        switch (_controller.state.status) {
          case AdminWorkspaceStatus.loading:
            if (snapshot != null) {
              return AdminWorkspaceControllerScope(
                controller: _controller,
                child: registration.builder(context, snapshot),
              );
            }
            return const AdminLoading();
          case AdminWorkspaceStatus.refreshing:
          case AdminWorkspaceStatus.ready:
            if (snapshot == null) {
              return const AdminLoading();
            }
            return AdminWorkspaceControllerScope(
              controller: _controller,
              child: registration.builder(context, snapshot),
            );
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
            return _StateModule(
              section: widget.section,
              title: 'No records matched this workspace',
              message:
                  _controller.state.message ??
                  'The workspace loaded successfully, but the current filters returned no rows.',
            );
          case AdminWorkspaceStatus.offline:
            return _StateModule(
              section: widget.section,
              title: 'Workspace offline',
              message:
                  _controller.state.message ??
                  'The admin runtime is offline and could not refresh this workspace.',
            );
        }
      },
    );
  }
}

class _StateModule extends StatelessWidget {
  const _StateModule({
    required this.section,
    required this.title,
    required this.message,
  });

  final PortalSectionData section;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Admin / ${section.title}',
      title: section.title,
      description: section.summary,
      child: AdminEmptyState(
        title: title,
        description: message,
        actionLabel: 'Refresh this view or adjust the filters.',
      ),
    );
  }
}

class _PermissionDeniedModule extends StatelessWidget {
  const _PermissionDeniedModule({required this.section, required this.message});

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
        actionLabel: 'Ask an administrator to grant access to this workspace.',
      ),
    );
  }
}

class _ErrorModule extends StatelessWidget {
  const _ErrorModule({required this.section, required this.message});

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
        actionLabel: 'Refresh the workspace or review the backend contract.',
      ),
    );
  }
}

Uri? _currentUriOrNull(BuildContext context) {
  try {
    return GoRouterState.of(context).uri;
  } catch (_) {
    return null;
  }
}

String? _readOptionalQuery(Map<String, String> queryParameters, String key) {
  final value = queryParameters[key]?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

int? _readPositiveInt(String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed < 1) {
    return null;
  }
  return parsed;
}

bool _mapsEqual(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
