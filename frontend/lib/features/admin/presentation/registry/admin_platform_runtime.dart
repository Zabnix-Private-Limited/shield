import 'package:flutter/widgets.dart';

import '../../shared/controllers/admin_workspace_controller.dart';
import '../../shared/engine/exports.dart';

typedef AdminWorkspaceRenderer =
    Widget Function(BuildContext context, AdminWorkspaceSnapshot snapshot);

class AdminWorkspaceRegistration {
  const AdminWorkspaceRegistration({
    required this.workspace,
    required this.navigation,
    required this.schema,
    required this.capabilities,
    required this.builder,
  });

  final AdminWorkspaceDefinition workspace;
  final AdminNavigationDefinition navigation;
  final AdminWorkspaceSchemaDefinition schema;
  final Set<String> capabilities;
  final AdminWorkspaceRenderer builder;
}

class AdminPlatformRuntime {
  AdminPlatformRuntime._({
    required this.workspaceRegistry,
    required this.navigationRegistry,
    required this.capabilityRegistry,
    required this.eventBus,
    required this.schemaRepository,
    required this.permissionGateway,
    required AdminWorkspaceRepository Function(
      AdminWorkspaceDefinition workspace,
    )
    repositoryResolver,
    required Map<String, AdminWorkspaceRegistration> registrations,
    required Map<String, AdminWorkspaceSchemaDefinition> schemas,
  }) : _repositoryResolver = repositoryResolver,
       _registrations = registrations,
       _schemas = schemas;

  factory AdminPlatformRuntime.bootstrap({
    required List<AdminWorkspaceRegistration> registrations,
    AdminEventBus? eventBus,
    AdminWorkspaceSchemaRepository? schemaRepository,
    AdminWorkspacePermissionGateway? permissionGateway,
    AdminWorkspaceRepository Function(AdminWorkspaceDefinition workspace)?
    repositoryResolver,
  }) {
    final workspaceRegistry = AdminWorkspaceRegistry();
    final navigationRegistry = AdminNavigationRegistry();
    final capabilityRegistry = AdminCapabilityRegistry();
    final registrationMap = <String, AdminWorkspaceRegistration>{};
    final schemas = <String, AdminWorkspaceSchemaDefinition>{};

    for (final registration in registrations) {
      workspaceRegistry.register(registration.workspace);
      navigationRegistry.register(registration.navigation);
      capabilityRegistry.register(
        AdminCapabilityBinding(
          workspaceId: registration.workspace.id,
          capabilities: registration.capabilities,
        ),
      );
      registrationMap[registration.workspace.id] = registration;
      schemas[registration.workspace.id] = registration.schema;
    }

    return AdminPlatformRuntime._(
      workspaceRegistry: workspaceRegistry,
      navigationRegistry: navigationRegistry,
      capabilityRegistry: capabilityRegistry,
      eventBus: eventBus ?? AdminEventBus(),
      schemaRepository:
          schemaRepository ?? _StaticAdminWorkspaceSchemaRepository(schemas),
      permissionGateway:
          permissionGateway ?? const _AllowAllAdminWorkspacePermissionGateway(),
      repositoryResolver: repositoryResolver ?? _noopRepositoryResolver,
      registrations: registrationMap,
      schemas: schemas,
    );
  }

  final AdminWorkspaceRegistry workspaceRegistry;
  final AdminNavigationRegistry navigationRegistry;
  final AdminCapabilityRegistry capabilityRegistry;
  final AdminEventBus eventBus;
  final AdminWorkspaceSchemaRepository schemaRepository;
  final AdminWorkspacePermissionGateway permissionGateway;
  final AdminWorkspaceRepository Function(AdminWorkspaceDefinition workspace)
  _repositoryResolver;
  final Map<String, AdminWorkspaceRegistration> _registrations;
  final Map<String, AdminWorkspaceSchemaDefinition> _schemas;

  AdminWorkspaceRegistration? registrationFor(String workspaceId) {
    return _registrations[workspaceId];
  }

  AdminWorkspaceSchemaDefinition? schemaFor(String workspaceId) {
    return _schemas[workspaceId];
  }

  AdminWorkspaceController createWorkspaceController() {
    return AdminWorkspaceController(
      workspaceRegistry: workspaceRegistry,
      navigationRegistry: navigationRegistry,
      schemaRepository: schemaRepository,
      permissionGateway: permissionGateway,
      repositoryResolver: _repositoryResolver,
      eventBus: eventBus,
    );
  }
}

AdminWorkspaceRepository _noopRepositoryResolver(
  AdminWorkspaceDefinition workspace,
) {
  return const _NoopAdminWorkspaceRepository();
}

class _StaticAdminWorkspaceSchemaRepository
    implements AdminWorkspaceSchemaRepository {
  const _StaticAdminWorkspaceSchemaRepository(this._schemas);

  final Map<String, AdminWorkspaceSchemaDefinition> _schemas;

  @override
  Future<AdminWorkspaceSchemaDefinition> loadSchema(
    AdminWorkspaceDefinition workspace,
  ) async {
    final schema = _schemas[workspace.id];
    if (schema == null) {
      throw StateError('Workspace schema "${workspace.id}" is not registered.');
    }
    return schema;
  }
}

class _AllowAllAdminWorkspacePermissionGateway
    implements AdminWorkspacePermissionGateway {
  const _AllowAllAdminWorkspacePermissionGateway();

  @override
  Future<bool> canAccess(
    AdminWorkspaceDefinition workspace, {
    String? userId,
  }) async {
    return true;
  }

  @override
  Future<Set<String>> permissionsFor(
    AdminWorkspaceDefinition workspace, {
    String? userId,
  }) async {
    return {workspace.permissionKey};
  }
}

class _NoopAdminWorkspaceRepository implements AdminWorkspaceRepository {
  const _NoopAdminWorkspaceRepository();

  @override
  Future<Object?> loadWorkspaceData(AdminWorkspaceDefinition workspace) async {
    return null;
  }
}
