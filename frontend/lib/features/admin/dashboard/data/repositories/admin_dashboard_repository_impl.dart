import '../../domain/entities/admin_dashboard_entity.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_dashboard_remote_data_source.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  AdminDashboardRepositoryImpl({
    AdminDashboardRemoteDataSource? remoteDataSource,
    Duration? cacheTtl,
  }) : _remoteDataSource = remoteDataSource ?? AdminDashboardRemoteDataSource(),
       _cacheTtl = cacheTtl ?? const Duration(minutes: 2);

  final AdminDashboardRemoteDataSource _remoteDataSource;
  final Duration _cacheTtl;

  AdminDashboardEntity? _cachedEntity;
  DateTime? _cachedAt;

  @override
  Future<AdminDashboardEntity> load({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedEntity != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cachedEntity!;
    }

    final dto = await _remoteDataSource.fetch();
    final entity = dto.toEntity();
    _cachedEntity = entity;
    _cachedAt = DateTime.now();
    return entity;
  }
}
