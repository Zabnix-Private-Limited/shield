import 'admin_navigation_definition.dart';

class AdminNavigationRegistry {
  final Map<String, AdminNavigationDefinition> _byWorkspaceId =
      <String, AdminNavigationDefinition>{};
  final Map<String, AdminNavigationDefinition> _byRoute =
      <String, AdminNavigationDefinition>{};

  void register(AdminNavigationDefinition definition) {
    if (_byWorkspaceId.containsKey(definition.workspaceId)) {
      throw StateError(
        'Admin navigation for workspace "${definition.workspaceId}" is already registered.',
      );
    }
    if (_byRoute.containsKey(definition.route)) {
      throw StateError(
        'Admin navigation route "${definition.route}" is already registered.',
      );
    }
    _byWorkspaceId[definition.workspaceId] = definition;
    _byRoute[definition.route] = definition;
  }

  AdminNavigationDefinition? findByWorkspaceId(String workspaceId) {
    return _byWorkspaceId[workspaceId];
  }

  AdminNavigationDefinition? findByRoute(String route) => _byRoute[route];

  List<AdminNavigationDefinition> get all =>
      List<AdminNavigationDefinition>.unmodifiable(_byWorkspaceId.values);
}
