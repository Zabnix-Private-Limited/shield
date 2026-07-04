import 'admin_workspace_definition.dart';
import 'admin_workspace_schema_definition.dart';

abstract class AdminWorkspaceSchemaRepository {
  Future<AdminWorkspaceSchemaDefinition> loadSchema(
    AdminWorkspaceDefinition workspace,
  );
}
