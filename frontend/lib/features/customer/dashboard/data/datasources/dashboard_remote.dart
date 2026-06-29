import '../models/dashboard_model.dart';
import '../../../../../shared/services/api_service.dart';

class DashboardRemoteDataSource {
  Future<DashboardModel> fetch(String customerId) async {
    final payload = await ApiService.getCustomerDashboardBundle(customerId);
    return DashboardModel.fromJson(payload);
  }
}
