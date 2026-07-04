import 'admin_workspace_definition.dart';

class AdminWorkspaceRegistry {
  final Map<String, AdminWorkspaceDefinition> _workspaces =
      <String, AdminWorkspaceDefinition>{};

  void register(AdminWorkspaceDefinition workspace) {
    if (_workspaces.containsKey(workspace.id)) {
      throw StateError(
        'Admin workspace "${workspace.id}" is already registered.',
      );
    }
    _workspaces[workspace.id] = workspace;
  }

  AdminWorkspaceDefinition? findById(String id) => _workspaces[id];

  List<AdminWorkspaceDefinition> get all =>
      List<AdminWorkspaceDefinition>.unmodifiable(_workspaces.values);
}
