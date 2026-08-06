import '../datasources/wallet_local.dart';
import '../datasources/wallet_remote.dart';
import '../models/wallet_model.dart';
import '../../../../../shared/models/wallet.dart';

class WalletRepository {
  WalletRepository({
    WalletRemoteDataSource? remote,
    WalletLocalDataSource? local,
  }) : _remote = remote ?? WalletRemoteDataSource(),
       _local = local ?? WalletLocalDataSource();

  final WalletRemoteDataSource _remote;
  final WalletLocalDataSource _local;

  Future<WalletModel?> loadCachedWallet(String customerId) {
    return _local.load(customerId);
  }

  Future<WalletModel> loadWallet(String customerId) async {
    try {
      final wallet = await _remote.fetch(customerId);
      await _local.save(customerId, wallet);
      return wallet;
    } catch (_) {
      final cached = await _local.load(customerId);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<WalletModel> refreshWallet(String customerId) async {
    final wallet = await _remote.fetch(customerId);
    await _local.save(customerId, wallet);
    return wallet;
  }

  Future<List<WalletTransaction>> loadTransactions(
    String walletId, {
    DateTime? from,
    DateTime? to,
    String? transactionType,
  }) => _remote.fetchTransactions(
    walletId,
    from: from,
    to: to,
    transactionType: transactionType,
  );

  Future<void> invalidateCache(String customerId) {
    return _local.clear(customerId);
  }
}
