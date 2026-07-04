import 'admin_workspace_definition.dart';

abstract class AdminWorkspacePermissionGateway {
  Future<bool> canAccess(
    AdminWorkspaceDefinition workspace, {
    String? userId,
  });

  Future<Set<String>> permissionsFor(
    AdminWorkspaceDefinition workspace, {
    String? userId,
  });
}
