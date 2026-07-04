import 'admin_data_source_definition.dart';
import 'admin_view_definition.dart';

class AdminWorkspaceDefinition {
  const AdminWorkspaceDefinition({
    required this.id,
    required this.title,
    required this.iconKey,
    required this.permissionKey,
    required this.dataSource,
    required this.views,
  });

  final String id;
  final String title;
  final String iconKey;
  final String permissionKey;
  final AdminDataSourceDefinition dataSource;
  final List<AdminViewDefinition> views;
}
