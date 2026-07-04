class AdminNavigationDefinition {
  const AdminNavigationDefinition({
    required this.workspaceId,
    required this.route,
    required this.title,
    required this.iconKey,
    required this.permissionKey,
    required this.breadcrumbs,
    required this.defaultViewId,
  });

  final String workspaceId;
  final String route;
  final String title;
  final String iconKey;
  final String permissionKey;
  final List<String> breadcrumbs;
  final String defaultViewId;
}
