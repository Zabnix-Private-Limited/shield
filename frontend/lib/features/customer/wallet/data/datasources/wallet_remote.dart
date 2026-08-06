import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/models/wallet.dart';
import '../models/wallet_model.dart';

class WalletRemoteDataSource {
  Future<WalletModel> fetch(String customerId) async {
    final payload = await ApiService.getCustomerWalletBundle(customerId);
    return WalletModel.fromJson(payload);
  }

  Future<List<WalletTransaction>> fetchTransactions(
    String walletId, {
    DateTime? from,
    DateTime? to,
    String? transactionType,
  }) => ApiService.getWalletTransactions(
    walletId,
    from: from,
    to: to,
    transactionType: transactionType,
  );
}
