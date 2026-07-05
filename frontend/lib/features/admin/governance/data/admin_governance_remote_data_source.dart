import '../../../../../shared/services/api_service.dart';

class AdminGovernanceRemoteDataSource {
  final Map<String, Map<String, dynamic>> _cache =
      <String, Map<String, dynamic>>{};

  Future<Map<String, dynamic>> fetchWorkspace(
    String workspaceId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(workspaceId)) {
      return Map<String, dynamic>.from(_cache[workspaceId]!);
    }

    final payload = await ApiService.getAdminGovernanceWorkspace(
      workspaceId,
      forceRefresh: forceRefresh,
    );
    _cache[workspaceId] = Map<String, dynamic>.from(payload);
    return Map<String, dynamic>.from(payload);
  }
}
