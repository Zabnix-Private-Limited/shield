import 'admin_workspace_definition.dart';

class AdminWorkspaceQuery {
  const AdminWorkspaceQuery({
    this.search,
    this.status,
    this.tab,
    this.selectedId,
    this.sortKey,
    this.sortDirection,
    this.page = 1,
    this.pageSize = 25,
  });

  final String? search;
  final String? status;
  final String? tab;
  final String? selectedId;
  final String? sortKey;
  final String? sortDirection;
  final int page;
  final int pageSize;

  AdminWorkspaceQuery copyWith({
    String? search,
    bool clearSearch = false,
    String? status,
    bool clearStatus = false,
    String? tab,
    bool clearTab = false,
    String? selectedId,
    bool clearSelectedId = false,
    String? sortKey,
    bool clearSortKey = false,
    String? sortDirection,
    bool clearSortDirection = false,
    int? page,
    int? pageSize,
  }) {
    return AdminWorkspaceQuery(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      tab: clearTab ? null : (tab ?? this.tab),
      selectedId:
          clearSelectedId ? null : (selectedId ?? this.selectedId),
      sortKey: clearSortKey ? null : (sortKey ?? this.sortKey),
      sortDirection: clearSortDirection
          ? null
          : (sortDirection ?? this.sortDirection),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (status != null && status!.trim().isNotEmpty) 'status': status!.trim(),
      if (tab != null && tab!.trim().isNotEmpty) 'tab': tab!.trim(),
      if (selectedId != null && selectedId!.trim().isNotEmpty)
        'selected_id': selectedId!.trim(),
      if (sortKey != null && sortKey!.trim().isNotEmpty)
        'sort_key': sortKey!.trim(),
      if (sortDirection != null && sortDirection!.trim().isNotEmpty)
        'sort_direction': sortDirection!.trim(),
      if (page != 1) 'page': page,
      if (pageSize != 25) 'page_size': pageSize,
    };
  }
}

abstract class AdminWorkspaceRepository {
  Future<Object?> loadWorkspaceData(
    AdminWorkspaceDefinition workspace, {
    AdminWorkspaceQuery query = const AdminWorkspaceQuery(),
    bool forceRefresh = false,
  });

  Future<Map<String, dynamic>> loadWorkspaceForm(
    AdminWorkspaceDefinition workspace, {
    required String formId,
    String? recordId,
  });

  Future<Map<String, dynamic>> executeWorkspaceAction(
    AdminWorkspaceDefinition workspace, {
    required String actionId,
    Map<String, Object?> payload = const <String, Object?>{},
  });

  Future<Map<String, dynamic>> executeBulkWorkspaceAction(
    AdminWorkspaceDefinition workspace, {
    required String actionId,
    required List<String> recordIds,
    Map<String, Object?> payload = const <String, Object?>{},
  });
}
