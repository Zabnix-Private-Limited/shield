import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/admin/shared/engine/exports.dart';
import 'package:shield/features/admin/shared/presentation/widgets/admin_backend_workspace_module.dart';

void main() {
  testWidgets(
    'AdminBackendWorkspaceModule renders backend workspace payload sections',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const workspace = AdminWorkspaceDefinition(
        id: 'customers',
        title: 'Customers',
        iconKey: 'customers',
        permissionKey: 'customers.view',
        dataSource: AdminDataSourceDefinition(
          scope: 'customers',
          endpoint: '/admin/workspaces/customers',
        ),
        views: [
          AdminViewDefinition(
            id: 'split',
            type: AdminViewType.split,
            title: 'Customers',
          ),
        ],
      );
      const navigation = AdminNavigationDefinition(
        workspaceId: 'customers',
        route: '/portal/super-admin/customers',
        title: 'Customers',
        iconKey: 'customers',
        permissionKey: 'customers.view',
        breadcrumbs: ['Super Admin', 'Customers'],
        defaultViewId: 'split',
      );
      const schema = AdminWorkspaceSchemaDefinition(
        workspaceId: 'customers',
        defaultViewId: 'split',
        views: [
          AdminViewDefinition(
            id: 'split',
            type: AdminViewType.split,
            title: 'Customers',
          ),
        ],
      );
      const snapshot = AdminWorkspaceSnapshot(
        workspace: workspace,
        navigation: navigation,
        schema: schema,
        permissions: {'customers.view'},
        data: {
          'header': {
            'eyebrow': 'Admin / Customer operations',
            'title': 'Customers',
            'description': 'Live customer workspace',
            'primaryActionLabel': 'Create customer',
            'secondaryActionLabel': 'Review approvals',
          },
          'toolbar': {
            'searchHint': 'Search customers',
            'tabs': ['Overview', 'Timeline'],
            'filters': ['ACTIVE', 'PENDING'],
          },
          'metrics': [
            {'label': 'Customers', 'value': '12', 'note': 'live rows'},
          ],
          'panels': {
            'left': {
              'title': 'Customer list',
              'subtitle': 'Live rows',
              'type': 'list',
              'items': [
                {
                  'title': 'Arun Thomas',
                  'subtitle': 'CUST-001',
                  'meta': 'Kochi',
                  'status': 'ACTIVE',
                },
              ],
            },
            'center': {
              'title': 'Customer profile',
              'subtitle': 'Primary details',
              'type': 'details',
              'details': [
                {'label': 'Membership', 'value': 'Gold'},
              ],
            },
            'right': {
              'title': 'Timeline',
              'subtitle': 'Recent history',
              'type': 'table',
              'columns': [
                {'key': 'event', 'label': 'Event'},
                {'key': 'time', 'label': 'Time'},
              ],
              'rows': [
                {'event': 'Registered', 'time': 'Today'},
              ],
            },
          },
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminBackendWorkspaceModule(snapshot: snapshot),
          ),
        ),
      );

      expect(find.text('Live customer workspace'), findsOneWidget);
      expect(find.text('Create customer'), findsNothing);
      expect(find.text('Arun Thomas'), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
      expect(find.text('Registered'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
