import '../navigation/admin_navigation_definition.dart';
import 'admin_workspace_definition.dart';
import 'admin_workspace_schema_definition.dart';

class AdminWorkspaceSnapshot {
  const AdminWorkspaceSnapshot({
    required this.workspace,
    required this.navigation,
    required this.schema,
    required this.permissions,
    required this.data,
  });

  final AdminWorkspaceDefinition workspace;
  final AdminNavigationDefinition navigation;
  final AdminWorkspaceSchemaDefinition schema;
  final Set<String> permissions;
  final Object? data;
}
