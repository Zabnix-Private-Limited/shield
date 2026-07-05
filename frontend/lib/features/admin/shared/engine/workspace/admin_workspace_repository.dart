import 'admin_workspace_definition.dart';

class AdminWorkspaceQuery {
  const AdminWorkspaceQuery({
    this.search,
    this.status,
    this.tab,
    this.page = 1,
    this.pageSize = 25,
  });

  final String? search;
  final String? status;
  final String? tab;
  final int page;
  final int pageSize;

  AdminWorkspaceQuery copyWith({
    String? search,
    bool clearSearch = false,
    String? status,
    bool clearStatus = false,
    String? tab,
    bool clearTab = false,
    int? page,
    int? pageSize,
  }) {
    return AdminWorkspaceQuery(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      tab: clearTab ? null : (tab ?? this.tab),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (status != null && status!.trim().isNotEmpty) 'status': status!.trim(),
      if (tab != null && tab!.trim().isNotEmpty) 'tab': tab!.trim(),
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
}
