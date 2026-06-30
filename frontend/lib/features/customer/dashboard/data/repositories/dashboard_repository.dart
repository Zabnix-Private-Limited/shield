import '../datasources/dashboard_local.dart';
import '../datasources/dashboard_remote.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  DashboardRepository({
    DashboardRemoteDataSource? remote,
    DashboardLocalDataSource? local,
  }) : _remote = remote ?? DashboardRemoteDataSource(),
       _local = local ?? DashboardLocalDataSource();

  final DashboardRemoteDataSource _remote;
  final DashboardLocalDataSource _local;

  Future<DashboardModel> loadDashboard(String customerId) async {
    try {
      final dashboard = await _remote.fetch(customerId);
      await _local.save(customerId, dashboard);
      return dashboard;
    } catch (_) {
      final cached = await _local.load(customerId);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<DashboardModel> refreshDashboard(String customerId) async {
    final dashboard = await _remote.fetch(customerId);
    await _local.save(customerId, dashboard);
    return dashboard;
  }

  Future<void> invalidateCache(String customerId) {
    return _local.clear(customerId);
  }
}
