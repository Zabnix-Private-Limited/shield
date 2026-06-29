import 'package:hive/hive.dart';

import '../../domain/services/dashboard_cache_policy.dart';
import '../models/dashboard_model.dart';

class DashboardLocalDataSource {
  Future<DashboardModel?> load() async {
    final box = await Hive.openBox<String>(DashboardCachePolicy.boxName);
    final cached = box.get(DashboardCachePolicy.cacheKey);
    if (cached == null || cached.trim().isEmpty) {
      return null;
    }
    return DashboardModel.fromCache(cached);
  }

  Future<void> save(DashboardModel model) async {
    final box = await Hive.openBox<String>(DashboardCachePolicy.boxName);
    await box.put(DashboardCachePolicy.cacheKey, model.toCache());
  }

  Future<void> clear() async {
    final box = await Hive.openBox<String>(DashboardCachePolicy.boxName);
    await box.delete(DashboardCachePolicy.cacheKey);
  }
}
