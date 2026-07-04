import 'admin_view_definition.dart';

class AdminWorkspaceSchemaDefinition {
  const AdminWorkspaceSchemaDefinition({
    required this.workspaceId,
    required this.defaultViewId,
    required this.views,
  });

  final String workspaceId;
  final String defaultViewId;
  final List<AdminViewDefinition> views;
}
