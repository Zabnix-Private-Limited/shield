import 'package:hive/hive.dart';

import '../../domain/services/wallet_cache_policy.dart';
import '../models/wallet_model.dart';

class WalletLocalDataSource {
  Future<WalletModel?> load(String customerId) async {
    final box = await Hive.openBox<String>(WalletCachePolicy.boxName);
    final cached = box.get(WalletCachePolicy.cacheKeyFor(customerId));
    if (cached == null || cached.trim().isEmpty) {
      return null;
    }
    return WalletModel.fromCache(cached);
  }

  Future<void> save(String customerId, WalletModel model) async {
    final box = await Hive.openBox<String>(WalletCachePolicy.boxName);
    await box.put(WalletCachePolicy.cacheKeyFor(customerId), model.toCache());
  }

  Future<void> clear(String customerId) async {
    final box = await Hive.openBox<String>(WalletCachePolicy.boxName);
    await box.delete(WalletCachePolicy.cacheKeyFor(customerId));
  }
}
