import '../datasources/wallet_local.dart';
import '../datasources/wallet_remote.dart';
import '../models/wallet_model.dart';

class WalletRepository {
  WalletRepository({
    WalletRemoteDataSource? remote,
    WalletLocalDataSource? local,
  }) : _remote = remote ?? WalletRemoteDataSource(),
       _local = local ?? WalletLocalDataSource();

  final WalletRemoteDataSource _remote;
  final WalletLocalDataSource _local;

  Future<WalletModel?> loadCachedWallet() {
    return _local.load();
  }

  Future<WalletModel> loadWallet(String customerId) async {
    try {
      final wallet = await _remote.fetch(customerId);
      await _local.save(wallet);
      return wallet;
    } catch (_) {
      final cached = await _local.load();
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<WalletModel> refreshWallet(String customerId) async {
    final wallet = await _remote.fetch(customerId);
    await _local.save(wallet);
    return wallet;
  }

  Future<void> invalidateCache() {
    return _local.clear();
  }
}
