import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/admin/customers/data/repositories/mock_admin_customer_repository.dart';
import 'package:shield/features/admin/customers/domain/entities/admin_customer_summary.dart';
import 'package:shield/features/admin/customers/domain/repositories/admin_customer_repository.dart';
import 'package:shield/features/admin/shared/controllers/admin_navigation_controller.dart';
import 'package:shield/features/admin/shared/controllers/admin_workspace_controller.dart';
import 'package:shield/features/admin/shared/engine/exports.dart';

void main() {
  group('Admin navigation platform', () {
    test('resolves navigation definitions by route and keeps active workspace in sync', () {
      final registry = AdminNavigationRegistry()
        ..register(
          const AdminNavigationDefinition(
            workspaceId: 'dashboard',
            route: '/portal/super-admin/dashboard',
            title: 'Dashboard',
            iconKey: 'dashboard',
            permissionKey: 'admin.dashboard.read',
            breadcrumbs: ['Super Admin', 'Dashboard'],
            defaultViewId: 'overview',
          ),
        )
        ..register(
          const AdminNavigationDefinition(
            workspaceId: 'customers',
            route: '/portal/super-admin/customers',
            title: 'Customers',
            iconKey: 'customers',
            permissionKey: 'admin.customers.read',
            breadcrumbs: ['Super Admin', 'Customers'],
            defaultViewId: 'table',
          ),
        );

      final controller = AdminNavigationController(
        navigationRegistry: registry,
        initialWorkspaceId: 'dashboard',
      );

      expect(controller.activeWorkspaceId, 'dashboard');
      expect(controller.activeRoute, '/portal/super-admin/dashboard');

      controller.activateRoute('/portal/super-admin/customers');

      expect(controller.activeWorkspaceId, 'customers');
      expect(controller.activeRoute, '/portal/super-admin/customers');
      expect(controller.activeNavigation?.breadcrumbs, ['Super Admin', 'Customers']);
    });
  });

  group('AdminWorkspaceController', () {
    test('loads workspace definition, schema, permissions, data, and emits metadata-rich events', () async {
      final workspaceRegistry = AdminWorkspaceRegistry()
        ..register(
          const AdminWorkspaceDefinition(
            id: 'customers',
            title: 'Customers',
            iconKey: 'customers',
            permissionKey: 'admin.customers.read',
            dataSource: AdminDataSourceDefinition(
              scope: 'customers',
              endpoint: '/admin/customers',
            ),
            views: [],
          ),
        );
      final navigationRegistry = AdminNavigationRegistry()
        ..register(
          const AdminNavigationDefinition(
            workspaceId: 'customers',
            route: '/portal/super-admin/customers',
            title: 'Customers',
            iconKey: 'customers',
            permissionKey: 'admin.customers.read',
            breadcrumbs: ['Super Admin', 'Customers'],
            defaultViewId: 'table',
          ),
        );
      final schema = AdminWorkspaceSchemaDefinition(
        workspaceId: 'customers',
        defaultViewId: 'table',
        views: [
          AdminViewDefinition(
            id: 'table',
            type: AdminViewType.table,
            title: 'Customer registry',
            table: AdminTableDefinition(
              entity: 'customer',
              columns: [
                const AdminTableColumnDefinition(
                  key: 'name',
                  label: 'Name',
                  valueType: AdminColumnValueType.text,
                ),
                const AdminTableColumnDefinition(
                  key: 'wallet',
                  label: 'Wallet',
                  valueType: AdminColumnValueType.currency,
                ),
              ],
              filters: [
                const AdminFilterDefinition(
                  key: 'status',
                  label: 'Status',
                  type: AdminFilterType.select,
                ),
              ],
              sorting: const [
                AdminSortDefinition(
                  key: 'name',
                  label: 'Name',
                ),
              ],
              actions: const [
                AdminActionDefinition(
                  id: 'refresh-customers',
                  type: AdminActionType.refresh,
                  label: 'Refresh',
                ),
              ],
            ),
          ),
        ],
      );
      final permissionGateway = _FakePermissionGateway(
        granted: {'admin.customers.read', 'admin.customers.export'},
      );
      final repository = _FakeWorkspaceRepository(
        result: const [
          {'id': 'CUS-000001', 'name': 'Zabnix', 'wallet': 1200},
        ],
      );
      final schemaRepository = _FakeSchemaRepository(schema);
      final eventBus = AdminEventBus();
      final events = <AdminEventDefinition>[];
      final subscription = eventBus.events.listen(events.add);

      final controller = AdminWorkspaceController(
        workspaceRegistry: workspaceRegistry,
        navigationRegistry: navigationRegistry,
        schemaRepository: schemaRepository,
        permissionGateway: permissionGateway,
        repositoryResolver: (_) => repository,
        eventBus: eventBus,
        clock: () => DateTime.utc(2026, 7, 4, 12),
        idGenerator: () => 'evt-001',
      );

      await controller.loadWorkspace(
        'customers',
        userId: 'USR-1',
        correlationId: 'corr-001',
      );

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(
        controller.state.status,
        AdminWorkspaceStatus.ready,
      );
      expect(
        controller.snapshot?.navigation.route,
        '/portal/super-admin/customers',
      );
      expect(
        controller.snapshot?.schema.defaultViewId,
        'table',
      );
      expect(
        controller.snapshot?.permissions,
        contains('admin.customers.export'),
      );
      expect(
        controller.snapshot?.data,
        const [
          {'id': 'CUS-000001', 'name': 'Zabnix', 'wallet': 1200},
        ],
      );
      expect(
        repository.callLog,
        ['load:customers'],
      );
      expect(
        events.map((event) => event.name),
        ['workspace.load.started', 'workspace.load.completed'],
      );
      expect(events.last.metadata.eventId, 'evt-001');
      expect(events.last.metadata.workspaceId, 'customers');
      expect(events.last.metadata.userId, 'USR-1');
      expect(events.last.metadata.correlationId, 'corr-001');
    });

    test('moves into permission denied state when workspace access is blocked', () async {
      final workspaceRegistry = AdminWorkspaceRegistry()
        ..register(
          const AdminWorkspaceDefinition(
            id: 'audit',
            title: 'Audit',
            iconKey: 'audit',
            permissionKey: 'admin.audit.read',
            dataSource: AdminDataSourceDefinition(
              scope: 'audit',
              endpoint: '/admin/audit',
            ),
            views: [],
          ),
        );

      final controller = AdminWorkspaceController(
        workspaceRegistry: workspaceRegistry,
        navigationRegistry: AdminNavigationRegistry(),
        schemaRepository: _FakeSchemaRepository(
          const AdminWorkspaceSchemaDefinition(
            workspaceId: 'audit',
            defaultViewId: 'table',
            views: [],
          ),
        ),
        permissionGateway: _FakePermissionGateway(granted: const <String>{}),
        repositoryResolver: (_) => _FakeWorkspaceRepository(result: const []),
        eventBus: AdminEventBus(),
      );

      await controller.loadWorkspace('audit', userId: 'USR-2');

      expect(controller.state.status, AdminWorkspaceStatus.permissionDenied);
      expect(controller.state.message, contains('admin.audit.read'));
    });
  });

  group('Admin action pipeline', () {
    test('runs middleware, dispatches repositories, and publishes correlated action events', () async {
      final bus = AdminCommandBus();
      final eventBus = AdminEventBus();
      final observed = <String>[];
      final events = <AdminEventDefinition>[];
      final subscription = eventBus.events.listen(events.add);

      bus.addMiddleware((command, next) async {
        observed.add('permission:${command.type}');
        return next(command);
      });
      bus.addMiddleware((command, next) async {
        observed.add('audit:${command.type}');
        return next(command);
      });
      bus.registerHandler('refresh', (command) async {
        observed.add('repository:${command.workspaceId}');
        return <String, Object?>{
          'workspaceId': command.workspaceId,
          'status': 'ok',
        };
      });

      final pipeline = AdminActionPipeline(
        commandBus: bus,
        eventBus: eventBus,
        clock: () => DateTime.utc(2026, 7, 4, 12, 30),
        idGenerator: () => 'cmd-001',
      );

      final result = await pipeline.execute(
        const AdminActionExecution(
          workspaceId: 'customers',
          userId: 'USR-1',
          action: AdminActionDefinition(
            id: 'refresh-customers',
            type: AdminActionType.refresh,
            label: 'Refresh',
          ),
          correlationId: 'corr-100',
          causationId: 'cause-100',
        ),
      );

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(result['status'], 'ok');
      expect(observed, [
        'permission:refresh',
        'audit:refresh',
        'repository:customers',
      ]);
      expect(events.single.name, 'action.completed');
      expect(events.single.metadata.eventId, 'cmd-001');
      expect(events.single.metadata.workspaceId, 'customers');
      expect(events.single.metadata.correlationId, 'corr-100');
      expect(events.single.metadata.causationId, 'cause-100');
    });
  });

  group('Customer repository contracts', () {
    test('supports in-memory customer mutations behind the repository interface', () async {
      final AdminCustomerRepository repository = MockAdminCustomerRepository(
        seed: const [
          AdminCustomerSummary(
            id: 'CUS-000001',
            name: 'Zabnix',
            phone: '9000000001',
            branch: 'HQ',
            status: 'ACTIVE',
          ),
        ],
      );

      final before = await repository.listCustomers();
      await repository.createCustomer(
        const AdminCustomerSummary(
          id: 'CUS-000002',
          name: 'Second Customer',
          phone: '9000000002',
          branch: 'North',
          status: 'PENDING',
        ),
      );
      await repository.updateCustomerStatus('CUS-000002', 'ACTIVE');
      final after = await repository.listCustomers();

      expect(before, hasLength(1));
      expect(after, hasLength(2));
      expect(after.last.status, 'ACTIVE');
    });
  });
}

class _FakeWorkspaceRepository implements AdminWorkspaceRepository {
  _FakeWorkspaceRepository({required this.result});

  final Object? result;
  final List<String> callLog = <String>[];

  @override
  Future<Object?> loadWorkspaceData(AdminWorkspaceDefinition workspace) async {
    callLog.add('load:${workspace.id}');
    return result;
  }
}

class _FakeSchemaRepository implements AdminWorkspaceSchemaRepository {
  _FakeSchemaRepository(this.schema);

  final AdminWorkspaceSchemaDefinition schema;

  @override
  Future<AdminWorkspaceSchemaDefinition> loadSchema(
    AdminWorkspaceDefinition workspace,
  ) async {
    return schema;
  }
}

class _FakePermissionGateway implements AdminWorkspacePermissionGateway {
  _FakePermissionGateway({required this.granted});

  final Set<String> granted;

  @override
  Future<bool> canAccess(
    AdminWorkspaceDefinition workspace, {
    String? userId,
  }) async {
    return granted.contains(workspace.permissionKey);
  }

  @override
  Future<Set<String>> permissionsFor(
    AdminWorkspaceDefinition workspace, {
    String? userId,
  }) async {
    return granted;
  }
}
