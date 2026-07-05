import '../../shared/engine/exports.dart';
import '../../../../../shared/services/api_service.dart';

class AdminGovernanceRemoteDataSource {
  final Map<String, Map<String, dynamic>> _cache =
      <String, Map<String, dynamic>>{};

  Future<Map<String, dynamic>> fetchWorkspace(
    String workspaceId, {
    AdminWorkspaceQuery query = const AdminWorkspaceQuery(),
    bool forceRefresh = false,
  }) async {
    final cacheKey = [
      workspaceId.trim().toLowerCase(),
      query.search?.trim() ?? '',
      query.status?.trim() ?? '',
      query.tab?.trim() ?? '',
      query.page,
      query.pageSize,
    ].join('|');
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(_cache[cacheKey]!);
    }

    final payload = await ApiService.getAdminGovernanceWorkspace(
      workspaceId,
      search: query.search,
      status: query.status,
      tab: query.tab,
      page: query.page,
      pageSize: query.pageSize,
      forceRefresh: forceRefresh,
    );
    _cache[cacheKey] = Map<String, dynamic>.from(payload);
    return Map<String, dynamic>.from(payload);
  }
}
