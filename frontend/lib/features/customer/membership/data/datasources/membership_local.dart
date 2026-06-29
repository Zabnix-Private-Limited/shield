import 'package:hive/hive.dart';

import '../../domain/services/membership_cache_policy.dart';
import '../models/membership_model.dart';

class MembershipLocalDataSource {
  Future<MembershipModel?> load() async {
    final box = await Hive.openBox<String>(MembershipCachePolicy.boxName);
    final cached = box.get(MembershipCachePolicy.cacheKey);
    if (cached == null || cached.trim().isEmpty) {
      return null;
    }
    return MembershipModel.fromCache(cached);
  }

  Future<void> save(MembershipModel model) async {
    final box = await Hive.openBox<String>(MembershipCachePolicy.boxName);
    await box.put(MembershipCachePolicy.cacheKey, model.toCache());
  }

  Future<void> clear() async {
    final box = await Hive.openBox<String>(MembershipCachePolicy.boxName);
    await box.delete(MembershipCachePolicy.cacheKey);
  }
}
