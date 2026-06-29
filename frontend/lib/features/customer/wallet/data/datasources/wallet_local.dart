import 'package:hive/hive.dart';

import '../../domain/services/wallet_cache_policy.dart';
import '../models/wallet_model.dart';

class WalletLocalDataSource {
  Future<WalletModel?> load() async {
    final box = await Hive.openBox<String>(WalletCachePolicy.boxName);
    final cached = box.get(WalletCachePolicy.cacheKey);
    if (cached == null || cached.trim().isEmpty) {
      return null;
    }
    return WalletModel.fromCache(cached);
  }

  Future<void> save(WalletModel model) async {
    final box = await Hive.openBox<String>(WalletCachePolicy.boxName);
    await box.put(WalletCachePolicy.cacheKey, model.toCache());
  }

  Future<void> clear() async {
    final box = await Hive.openBox<String>(WalletCachePolicy.boxName);
    await box.delete(WalletCachePolicy.cacheKey);
  }
}
