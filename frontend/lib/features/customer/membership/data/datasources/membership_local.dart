import 'package:hive/hive.dart';

import '../../domain/services/membership_cache_policy.dart';
import '../models/membership_model.dart';

class MembershipLocalDataSource {
  Future<MembershipModel?> load(String customerId) async {
    final box = await Hive.openBox<String>(MembershipCachePolicy.boxName);
    final cached = box.get(MembershipCachePolicy.cacheKeyFor(customerId));
    if (cached == null || cached.trim().isEmpty) {
      return null;
    }
    return MembershipModel.fromCache(cached);
  }

  Future<void> save(String customerId, MembershipModel model) async {
    final box = await Hive.openBox<String>(MembershipCachePolicy.boxName);
    await box.put(
      MembershipCachePolicy.cacheKeyFor(customerId),
      model.toCache(),
    );
  }

  Future<void> clear(String customerId) async {
    final box = await Hive.openBox<String>(MembershipCachePolicy.boxName);
    await box.delete(MembershipCachePolicy.cacheKeyFor(customerId));
  }
}
