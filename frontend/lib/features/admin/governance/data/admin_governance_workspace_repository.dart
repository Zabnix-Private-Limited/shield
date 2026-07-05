import '../../shared/engine/exports.dart';
import 'admin_governance_remote_data_source.dart';

class AdminGovernanceWorkspaceRepository implements AdminWorkspaceRepository {
  AdminGovernanceWorkspaceRepository({
    required AdminGovernanceRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AdminGovernanceRemoteDataSource _remoteDataSource;

  @override
  Future<Object?> loadWorkspaceData(AdminWorkspaceDefinition workspace) async {
    return _remoteDataSource.fetchWorkspace(workspace.id);
  }
}
