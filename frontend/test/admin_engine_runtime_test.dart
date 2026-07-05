import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/admin/customers/data/repositories/mock_admin_customer_repository.dart';
import 'package:shield/features/admin/customers/domain/entities/admin_customer_summary.dart';
import 'package:shield/features/admin/customers/domain/repositories/admin_customer_repository.dart';
import 'package:shield/features/admin/presentation/registry/admin_platform_runtime.dart';
import 'package:shield/features/admin/presentation/registry/admin_workspace_catalog.dart';
import 'package:shield/features/admin/presentation/screens/admin_portal_workspace.dart';
import 'package:shield/features/admin/shared/controllers/admin_navigation_controller.dart';
import 'package:shield/features/admin/shared/controllers/admin_workspace_controller.dart';
import 'package:shield/features/admin/shared/engine/exports.dart';
import 'package:shield/features/portal/presentation/portal_role_data.dart';
import 'package:shield/shared/models/shield_role.dart';
import 'package:flutter/material.dart';

void main() {
  group('AdminPlatformRuntime', () {
    test('bootstraps workspace, navigation, capability, and schema registries from the shared catalog', () {
      final runtime = AdminPlatformRuntime.bootstrap(
        registrations: AdminWorkspaceCatalog.registrations,
      );

      expect(runtime.registrationFor('settings')?.workspace.title, 'Settings');
      expect(
        runtime.workspaceRegistry.findById('platform')?.permissionKey,
        'admin.platform.read',
      );
      expect(
        runtime.navigationRegistry.findByWorkspaceId('notifications')?.route,
        '/portal/super-admin/notifications',
      );
      expect(runtime.capabilityRegistry.supports('settings', 'forms'), isTrue);
      expect(runtime.capabilityRegistry.supports('platform', 'tables'), isTrue);
      expect(
        runtime.schemaFor('audit')?.defaultViewId,
        'table',
      );
    });

    testWidgets('AdminPortalWorkspace renders through an injected runtime registration', (tester) async {
      final runtime = AdminPlatformRuntime.bootstrap(
        registrations: [
          AdminWorkspaceRegistration(
            workspace: const AdminWorkspaceDefinition(
              id: 'runtime-test',
              title: 'Runtime Test',
              iconKey: 'runtime-test',
              permissionKey: 'admin.runtime-test.read',
              dataSource: AdminDataSourceDefinition(
                scope: 'runtime-test',
                endpoint: '/admin/runtime-test',
              ),
              views: [
                AdminViewDefinition(
                  id: 'overview',
                  type: AdminViewType.detail,
                  title: 'Runtime Test',
                ),
              ],
            ),
            navigation: const AdminNavigationDefinition(
              workspaceId: 'runtime-test',
              route: '/portal/super-admin/runtime-test',
              title: 'Runtime Test',
              iconKey: 'runtime-test',
              permissionKey: 'admin.runtime-test.read',
              breadcrumbs: ['Super Admin', 'Runtime Test'],
              defaultViewId: 'overview',
            ),
            schema: const AdminWorkspaceSchemaDefinition(
              workspaceId: 'runtime-test',
              defaultViewId: 'overview',
              views: [
                AdminViewDefinition(
                  id: 'overview',
                  type: AdminViewType.detail,
                  title: 'Runtime Test',
                ),
              ],
            ),
            capabilities: const {'detail'},
            builder: _runtimeTestBuilder,
          ),
        ],
      );

      const section = PortalSectionData(
        key: 'runtime-test',
        title: 'Runtime Test',
        summary: 'Runtime registered section.',
        actions: <String>[],
        metrics: <PortalMetric>[],
        queueItems: <PortalListItem>[],
        recentItems: <PortalListItem>[],
        insightItems: <PortalListItem>[],
      );
      const portal = PortalRoleData(
        role: SHIELDRole.superAdmin,
        operatorName: 'Admin',
        headline: 'Platform runtime',
        regionLabel: 'System-wide administrative workspace',
        icon: Icons.security_outlined,
        accentColor: Colors.blue,
        sections: [section],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPortalWorkspace(
              portal: portal,
              section: section,
              runtime: runtime,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Registry runtime renderer'), findsOneWidget);
      expect(find.textContaining('module is reserved'), findsNothing);
    });
  });

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

Widget _runtimeTestBuilder(
  BuildContext context,
  AdminWorkspaceSnapshot snapshot,
) {
  return Text(snapshot.workspace.title == 'Runtime Test'
      ? 'Registry runtime renderer'
      : 'Unexpected workspace');
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
