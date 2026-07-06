import 'package:flutter/foundation.dart';

import '../engine/navigation/admin_navigation_definition.dart';
import '../engine/navigation/admin_navigation_registry.dart';

class AdminNavigationController extends ChangeNotifier {
  AdminNavigationController({
    required AdminNavigationRegistry navigationRegistry,
    required String initialWorkspaceId,
  }) : _navigationRegistry = navigationRegistry {
    _activeNavigation = _navigationRegistry.findByWorkspaceId(
      initialWorkspaceId,
    );
  }

  final AdminNavigationRegistry _navigationRegistry;
  AdminNavigationDefinition? _activeNavigation;

  String get activeSection => activeWorkspaceId;

  String get activeWorkspaceId => _activeNavigation?.workspaceId ?? 'dashboard';

  String? get activeRoute => _activeNavigation?.route;

  AdminNavigationDefinition? get activeNavigation => _activeNavigation;

  void activateWorkspace(String workspaceId) {
    final resolved = _navigationRegistry.findByWorkspaceId(workspaceId);
    if (resolved == null || identical(_activeNavigation, resolved)) {
      return;
    }
    _activeNavigation = resolved;
    notifyListeners();
  }

  void activateRoute(String route) {
    final resolved = _navigationRegistry.findByRoute(route);
    if (resolved == null || identical(_activeNavigation, resolved)) {
      return;
    }
    _activeNavigation = resolved;
    notifyListeners();
  }
}
