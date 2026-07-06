import 'package:hive/hive.dart';

import '../../domain/services/dashboard_cache_policy.dart';
import '../models/dashboard_model.dart';

class DashboardLocalDataSource {
  Future<DashboardModel?> load(String customerId) async {
    final box = await Hive.openBox<String>(DashboardCachePolicy.boxName);
    final cached = box.get(DashboardCachePolicy.cacheKeyFor(customerId));
    if (cached == null || cached.trim().isEmpty) {
      return null;
    }
    return DashboardModel.fromCache(cached);
  }

  Future<void> save(String customerId, DashboardModel model) async {
    final box = await Hive.openBox<String>(DashboardCachePolicy.boxName);
    await box.put(
      DashboardCachePolicy.cacheKeyFor(customerId),
      model.toCache(),
    );
  }

  Future<void> clear(String customerId) async {
    final box = await Hive.openBox<String>(DashboardCachePolicy.boxName);
    await box.delete(DashboardCachePolicy.cacheKeyFor(customerId));
  }
}
