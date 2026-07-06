import '../../shared/engine/exports.dart';
import 'admin_governance_remote_data_source.dart';

class AdminGovernanceWorkspaceRepository implements AdminWorkspaceRepository {
  AdminGovernanceWorkspaceRepository({
    required AdminGovernanceRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AdminGovernanceRemoteDataSource _remoteDataSource;

  @override
  Future<Object?> loadWorkspaceData(
    AdminWorkspaceDefinition workspace, {
    AdminWorkspaceQuery query = const AdminWorkspaceQuery(),
    bool forceRefresh = false,
  }) async {
    return _remoteDataSource.fetchWorkspace(
      workspace.id,
      query: query,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<Map<String, dynamic>> loadWorkspaceForm(
    AdminWorkspaceDefinition workspace, {
    required String formId,
    String? recordId,
  }) {
    return _remoteDataSource.fetchWorkspaceForm(
      workspace.id,
      formId: formId,
      recordId: recordId,
    );
  }

  @override
  Future<Map<String, dynamic>> executeWorkspaceAction(
    AdminWorkspaceDefinition workspace, {
    required String actionId,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    return _remoteDataSource.executeWorkspaceAction(
      workspace.id,
      actionId: actionId,
      payload: payload,
    );
  }

  @override
  Future<Map<String, dynamic>> executeBulkWorkspaceAction(
    AdminWorkspaceDefinition workspace, {
    required String actionId,
    required List<String> recordIds,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    return _remoteDataSource.executeBulkWorkspaceAction(
      workspace.id,
      actionId: actionId,
      recordIds: recordIds,
      payload: payload,
    );
  }
}
