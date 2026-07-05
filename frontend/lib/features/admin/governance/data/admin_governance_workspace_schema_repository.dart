import '../../shared/engine/exports.dart';
import 'admin_governance_remote_data_source.dart';

class AdminGovernanceWorkspaceSchemaRepository
    implements AdminWorkspaceSchemaRepository {
  AdminGovernanceWorkspaceSchemaRepository({
    required AdminGovernanceRemoteDataSource remoteDataSource,
    required Map<String, AdminWorkspaceSchemaDefinition> fallbackSchemas,
    required Set<String> governanceWorkspaceIds,
  }) : _remoteDataSource = remoteDataSource,
       _fallbackSchemas = fallbackSchemas,
       _governanceWorkspaceIds = governanceWorkspaceIds;

  final AdminGovernanceRemoteDataSource _remoteDataSource;
  final Map<String, AdminWorkspaceSchemaDefinition> _fallbackSchemas;
  final Set<String> _governanceWorkspaceIds;

  @override
  Future<AdminWorkspaceSchemaDefinition> loadSchema(
    AdminWorkspaceDefinition workspace,
  ) async {
    if (_governanceWorkspaceIds.contains(workspace.id)) {
      final payload = await _remoteDataSource.fetchWorkspace(workspace.id);
      final schema = payload['schema'];
      if (schema is Map<String, dynamic>) {
        return _parseSchema(workspace.id, schema);
      }
    }

    final fallback = _fallbackSchemas[workspace.id];
    if (fallback == null) {
      throw StateError('Workspace schema "${workspace.id}" is not registered.');
    }
    return fallback;
  }

  AdminWorkspaceSchemaDefinition _parseSchema(
    String workspaceId,
    Map<String, dynamic> raw,
  ) {
    final defaultViewId =
        (raw['defaultViewId'] ?? raw['default_view_id'] ?? 'detail')
            .toString()
            .trim();
    final rawViews = raw['views'] as List? ?? const <dynamic>[];
    final views = rawViews
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (view) => AdminViewDefinition(
            id: (view['id'] ?? defaultViewId).toString(),
            type: _parseViewType(view['type']?.toString()),
            title: (view['title'] ?? workspaceId).toString(),
          ),
        )
        .toList(growable: false);

    return AdminWorkspaceSchemaDefinition(
      workspaceId: workspaceId,
      defaultViewId: defaultViewId,
      views: views.isEmpty
          ? <AdminViewDefinition>[
              AdminViewDefinition(
                id: defaultViewId,
                type: AdminViewType.detail,
                title: workspaceId,
              ),
            ]
          : views,
    );
  }

  AdminViewType _parseViewType(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'table':
        return AdminViewType.table;
      case 'metrics':
        return AdminViewType.metrics;
      case 'cards':
        return AdminViewType.cards;
      case 'timeline':
        return AdminViewType.timeline;
      case 'split':
        return AdminViewType.split;
      default:
        return AdminViewType.detail;
    }
  }
}
