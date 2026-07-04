import 'admin_workspace_definition.dart';

abstract class AdminWorkspaceRepository {
  Future<Object?> loadWorkspaceData(AdminWorkspaceDefinition workspace);
}
