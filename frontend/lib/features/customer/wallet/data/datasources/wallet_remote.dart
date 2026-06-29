import '../../../../../shared/services/api_service.dart';
import '../models/wallet_model.dart';

class WalletRemoteDataSource {
  Future<WalletModel> fetch(String customerId) async {
    final payload = await ApiService.getCustomerWalletBundle(customerId);
    return WalletModel.fromJson(payload);
  }
}
