import 'package:flutter/foundation.dart';

import '../engine/events/admin_event_bus.dart';
import '../engine/events/admin_event_definition.dart';
import '../engine/events/admin_event_metadata.dart';
import '../engine/navigation/admin_navigation_definition.dart';
import '../engine/navigation/admin_navigation_registry.dart';
import '../engine/workspace/admin_workspace_definition.dart';
import '../engine/workspace/admin_workspace_permission_gateway.dart';
import '../engine/workspace/admin_workspace_registry.dart';
import '../engine/workspace/admin_workspace_repository.dart';
import '../engine/workspace/admin_workspace_schema_repository.dart';
import '../engine/workspace/admin_workspace_snapshot.dart';
import '../engine/workspace/admin_workspace_state.dart';

class AdminWorkspaceController extends ChangeNotifier {
  AdminWorkspaceController({
    required AdminWorkspaceRegistry workspaceRegistry,
    required AdminNavigationRegistry navigationRegistry,
    required AdminWorkspaceSchemaRepository schemaRepository,
    required AdminWorkspacePermissionGateway permissionGateway,
    required AdminWorkspaceRepository Function(AdminWorkspaceDefinition workspace)
    repositoryResolver,
    required AdminEventBus eventBus,
    DateTime Function()? clock,
    String Function()? idGenerator,
  }) : _workspaceRegistry = workspaceRegistry,
       _navigationRegistry = navigationRegistry,
       _schemaRepository = schemaRepository,
       _permissionGateway = permissionGateway,
       _repositoryResolver = repositoryResolver,
       _eventBus = eventBus,
       _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _defaultIdGenerator;

  final AdminWorkspaceRegistry _workspaceRegistry;
  final AdminNavigationRegistry _navigationRegistry;
  final AdminWorkspaceSchemaRepository _schemaRepository;
  final AdminWorkspacePermissionGateway _permissionGateway;
  final AdminWorkspaceRepository Function(AdminWorkspaceDefinition workspace)
  _repositoryResolver;
  final AdminEventBus _eventBus;
  final DateTime Function() _clock;
  final String Function() _idGenerator;
  String? _activeUserId;
  String? _activeCorrelationId;
  String? _activeWorkspaceId;
  AdminWorkspaceQuery _query = const AdminWorkspaceQuery();

  AdminWorkspaceState _state = const AdminWorkspaceState.loading(
    workspaceId: 'dashboard',
  );

  AdminWorkspaceState get state => _state;

  bool get isBusy =>
      _state.status == AdminWorkspaceStatus.loading ||
      _state.status == AdminWorkspaceStatus.refreshing;

  String? get error => _state.message;
  AdminWorkspaceQuery get query => _query;
  String? get activeWorkspaceId => _activeWorkspaceId;

  AdminWorkspaceSnapshot? get snapshot =>
      _state.payload as AdminWorkspaceSnapshot?;

  Future<void> loadWorkspace(
    String workspaceId, {
    String? userId,
    String? correlationId,
    AdminWorkspaceQuery query = const AdminWorkspaceQuery(),
    bool forceRefresh = false,
  }) async {
    _activeWorkspaceId = workspaceId;
    _activeUserId = userId;
    _activeCorrelationId = correlationId;
    _query = query;
    final workspace = _workspaceRegistry.findById(workspaceId);
    if (workspace == null) {
      _state = AdminWorkspaceState(
        workspaceId: workspaceId,
        status: AdminWorkspaceStatus.error,
        message: 'Workspace "$workspaceId" is not registered.',
      );
      notifyListeners();
      return;
    }

    final existingSnapshot = snapshot;
    _state =
        existingSnapshot == null
            ? AdminWorkspaceState.loading(
                workspaceId: workspaceId,
                payload: existingSnapshot,
              )
            : AdminWorkspaceState.ready(
                workspaceId: workspaceId,
                payload: existingSnapshot,
              ).toRefreshing();
    notifyListeners();

    final navigation = _navigationRegistry.findByWorkspaceId(workspaceId);
    final eventId = _idGenerator();
    final startedAt = _clock();

    _eventBus.publish(
      AdminEventDefinition(
        name: 'workspace.load.started',
        version: 1,
        metadata: AdminEventMetadata(
          eventId: eventId,
          workspaceId: workspaceId,
          userId: userId,
          timestamp: startedAt,
          correlationId: correlationId,
        ),
      ),
    );

    final canAccess = await _permissionGateway.canAccess(
      workspace,
      userId: userId,
    );
    if (!canAccess) {
      _state = AdminWorkspaceState.permissionDenied(
        workspaceId: workspaceId,
        message: 'Missing ${workspace.permissionKey}',
        payload: snapshot,
      );
      notifyListeners();
      return;
    }

    try {
      final permissions = await _permissionGateway.permissionsFor(
        workspace,
        userId: userId,
      );
      final schema = await _schemaRepository.loadSchema(workspace);
      final data = await _repositoryResolver(workspace).loadWorkspaceData(
        workspace,
        query: _query,
        forceRefresh: forceRefresh,
      );
      final resolvedNavigation =
          navigation ??
          AdminNavigationDefinition(
            workspaceId: workspace.id,
            route: '/portal/super-admin/${workspace.id}',
            title: workspace.title,
            iconKey: workspace.iconKey,
            permissionKey: workspace.permissionKey,
            breadcrumbs: ['Super Admin', workspace.title],
            defaultViewId: schema.defaultViewId,
          );
      final snapshot = AdminWorkspaceSnapshot(
        workspace: workspace,
        navigation: resolvedNavigation,
        schema: schema,
        permissions: permissions,
        data: data,
      );
      _state = AdminWorkspaceState.ready(
        workspaceId: workspaceId,
        payload: snapshot,
      );
      _eventBus.publish(
        AdminEventDefinition(
          name: 'workspace.load.completed',
          version: 1,
          metadata: AdminEventMetadata(
            eventId: eventId,
            workspaceId: workspaceId,
            userId: userId,
            timestamp: _clock(),
            correlationId: correlationId,
          ),
          payload: <String, Object?>{
            'defaultViewId': schema.defaultViewId,
            'route': resolvedNavigation.route,
          },
        ),
      );
    } catch (error) {
      _state = _state.toError(error.toString());
    }
    notifyListeners();
  }

  Future<void> refresh({bool forceRefresh = true}) async {
    final workspaceId = _activeWorkspaceId;
    if (workspaceId == null) {
      return;
    }
    await loadWorkspace(
      workspaceId,
      userId: _activeUserId,
      correlationId: _activeCorrelationId,
      query: _query,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> updateSearch(String value) {
    return _reload(
      _query.copyWith(
        search: value.trim().isEmpty ? null : value.trim(),
        clearSearch: value.trim().isEmpty,
        page: 1,
      ),
    );
  }

  Future<void> selectTab(String? tab) {
    final normalized = tab?.trim();
    return _reload(
      _query.copyWith(
        tab: normalized?.isEmpty ?? true ? null : normalized,
        clearTab: normalized?.isEmpty ?? true,
        page: 1,
      ),
    );
  }

  Future<void> toggleStatus(String status) {
    final normalized = status.trim();
    final isSame =
        _query.status?.trim().toLowerCase() == normalized.toLowerCase();
    return _reload(
      _query.copyWith(
        status: isSame ? null : normalized,
        clearStatus: isSame,
        page: 1,
      ),
    );
  }

  Future<void> _reload(AdminWorkspaceQuery query) async {
    final workspaceId = _activeWorkspaceId;
    if (workspaceId == null) {
      return;
    }
    await loadWorkspace(
      workspaceId,
      userId: _activeUserId,
      correlationId: _activeCorrelationId,
      query: query,
      forceRefresh: true,
    );
  }
}

String _defaultIdGenerator() => DateTime.now().microsecondsSinceEpoch.toString();
