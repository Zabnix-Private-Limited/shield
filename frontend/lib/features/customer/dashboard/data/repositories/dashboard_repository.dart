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
  static const _memoryCacheTtl = Duration(minutes: 1);
  static final Map<String, _DashboardMemoryEntry> _memoryCache = {};
  static final Map<String, Future<DashboardModel>> _inFlight = {};

  Future<DashboardModel> loadDashboard(String customerId) async {
    final cached = _memoryCache[customerId];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _memoryCacheTtl) {
      return cached.model;
    }
    final existing = _inFlight[customerId];
    if (existing != null) return existing;
    final request = _loadAndCache(customerId);
    _inFlight[customerId] = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlight[customerId], request)) {
        _inFlight.remove(customerId);
      }
    }
  }

  Future<DashboardModel> _loadAndCache(String customerId) async {
    try {
      final dashboard = await _remote.fetch(customerId);
      await _local.save(customerId, dashboard);
      _memoryCache[customerId] = _DashboardMemoryEntry(
        model: dashboard,
        fetchedAt: DateTime.now(),
      );
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
    _memoryCache[customerId] = _DashboardMemoryEntry(
      model: dashboard,
      fetchedAt: DateTime.now(),
    );
    return dashboard;
  }

  Future<void> invalidateCache(String customerId) async {
    _memoryCache.remove(customerId);
    _inFlight.remove(customerId);
    await _local.clear(customerId);
  }
}

class _DashboardMemoryEntry {
  const _DashboardMemoryEntry({required this.model, required this.fetchedAt});

  final DashboardModel model;
  final DateTime fetchedAt;
}
