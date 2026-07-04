import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/admin/shared/engine/actions/admin_command_bus.dart';
import 'package:shield/features/admin/shared/engine/actions/admin_command_definition.dart';
import 'package:shield/features/admin/shared/engine/registry/admin_capability_registry.dart';
import 'package:shield/features/admin/shared/engine/workspace/admin_data_source_definition.dart';
import 'package:shield/features/admin/shared/engine/workspace/admin_view_definition.dart';
import 'package:shield/features/admin/shared/engine/workspace/admin_workspace_definition.dart';
import 'package:shield/features/admin/shared/engine/workspace/admin_workspace_registry.dart';
import 'package:shield/features/admin/shared/engine/workspace/admin_workspace_state.dart';
import 'package:shield/features/admin/shared/engine/events/admin_event_bus.dart';
import 'package:shield/features/admin/shared/engine/events/admin_event_definition.dart';

void main() {
  group('AdminWorkspaceRegistry', () {
    test('registers workspaces and resolves them by id', () {
      final registry = AdminWorkspaceRegistry();
      const workspace = AdminWorkspaceDefinition(
        id: 'settings',
        title: 'Settings',
        iconKey: 'settings',
        permissionKey: 'admin.settings.read',
        dataSource: AdminDataSourceDefinition(scope: 'settings', endpoint: '/admin/settings/company'),
        views: [
          AdminViewDefinition(
            id: 'overview',
            type: AdminViewType.detail,
            title: 'Overview',
          ),
        ],
      );

      registry.register(workspace);

      expect(registry.all.single.id, 'settings');
      expect(registry.findById('settings'), workspace);
    });

    test('rejects duplicate workspace ids', () {
      final registry = AdminWorkspaceRegistry();
      const workspace = AdminWorkspaceDefinition(
        id: 'audit',
        title: 'Audit',
        iconKey: 'audit',
        permissionKey: 'admin.audit.read',
        dataSource: AdminDataSourceDefinition(scope: 'audit', endpoint: '/admin/audit/logs'),
        views: [
          AdminViewDefinition(
            id: 'table',
            type: AdminViewType.table,
            title: 'Audit logs',
          ),
        ],
      );

      registry.register(workspace);

      expect(() => registry.register(workspace), throwsStateError);
    });
  });

  group('AdminCapabilityRegistry', () {
    test('tracks declared capabilities per workspace', () {
      final registry = AdminCapabilityRegistry();

      registry.register(
        const AdminCapabilityBinding(
          workspaceId: 'customers',
          capabilities: {'forms', 'tables', 'search'},
        ),
      );

      expect(registry.capabilitiesFor('customers'), {'forms', 'tables', 'search'});
      expect(registry.supports('customers', 'tables'), isTrue);
      expect(registry.supports('customers', 'charts'), isFalse);
    });
  });

  group('AdminWorkspaceState', () {
    test('supports state transitions without losing last successful payload', () {
      const ready = AdminWorkspaceState.ready(
        workspaceId: 'platform',
        payload: {'services': 4},
      );

      final refreshing = ready.toRefreshing();
      final failure = refreshing.toError('load failed');

      expect(ready.status, AdminWorkspaceStatus.ready);
      expect(refreshing.status, AdminWorkspaceStatus.refreshing);
      expect(failure.status, AdminWorkspaceStatus.error);
      expect(failure.payload, {'services': 4});
      expect(failure.message, 'load failed');
    });

    test('creates permission denied state explicitly', () {
      const denied = AdminWorkspaceState.permissionDenied(
        workspaceId: 'settings',
        message: 'Missing admin.settings.read',
      );

      expect(denied.status, AdminWorkspaceStatus.permissionDenied);
      expect(denied.message, contains('admin.settings.read'));
    });
  });

  group('Admin buses', () {
    test('dispatches commands through middleware and handler', () async {
      final bus = AdminCommandBus();
      final received = <String>[];

      bus.addMiddleware((command, next) async {
        received.add('middleware:${command.type}');
        return next(command);
      });

      bus.registerHandler(
        'refresh-workspace',
        (command) async {
          received.add('handler:${command.type}');
          return command.payload['workspaceId'];
        },
      );

      final result = await bus.dispatch(
        const AdminCommandDefinition(
          type: 'refresh-workspace',
          payload: {'workspaceId': 'audit'},
        ),
      );

      expect(result, 'audit');
      expect(received, ['middleware:refresh-workspace', 'handler:refresh-workspace']);
    });

    test('publishes versioned events to subscribers', () async {
      final bus = AdminEventBus();
      final events = <AdminEventDefinition>[];

      final subscription = bus.events.listen(events.add);

      bus.publish(
        const AdminEventDefinition(
          name: 'WalletCredited',
          version: 2,
          payload: {'walletId': 'WAL-000001'},
        ),
      );

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(events.single.name, 'WalletCredited');
      expect(events.single.version, 2);
      expect(events.single.payload['walletId'], 'WAL-000001');
    });
  });
}
