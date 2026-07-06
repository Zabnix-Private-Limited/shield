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
      query.selectedId?.trim() ?? '',
      query.sortKey?.trim() ?? '',
      query.sortDirection?.trim() ?? '',
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
      selectedId: query.selectedId,
      sortKey: query.sortKey,
      sortDirection: query.sortDirection,
      page: query.page,
      pageSize: query.pageSize,
      forceRefresh: forceRefresh,
    );
    _cache[cacheKey] = Map<String, dynamic>.from(payload);
    return Map<String, dynamic>.from(payload);
  }

  Future<Map<String, dynamic>> fetchWorkspaceForm(
    String workspaceId, {
    required String formId,
    String? recordId,
  }) {
    return ApiService.getAdminGovernanceWorkspaceForm(
      workspaceId,
      formId: formId,
      recordId: recordId,
    );
  }

  Future<Map<String, dynamic>> executeWorkspaceAction(
    String workspaceId, {
    required String actionId,
    Map<String, Object?> payload = const <String, Object?>{},
  }) async {
    final response = await ApiService.executeAdminGovernanceWorkspaceAction(
      workspaceId,
      actionId: actionId,
      payload: payload,
    );
    _cache.removeWhere((key, _) => key.startsWith('${workspaceId.trim().toLowerCase()}|'));
    return response;
  }

  Future<Map<String, dynamic>> executeBulkWorkspaceAction(
    String workspaceId, {
    required String actionId,
    required List<String> recordIds,
    Map<String, Object?> payload = const <String, Object?>{},
  }) async {
    final response = await ApiService.executeAdminGovernanceWorkspaceBulkAction(
      workspaceId,
      actionId: actionId,
      recordIds: recordIds,
      payload: payload,
    );
    _cache.removeWhere((key, _) => key.startsWith('${workspaceId.trim().toLowerCase()}|'));
    return response;
  }
}
