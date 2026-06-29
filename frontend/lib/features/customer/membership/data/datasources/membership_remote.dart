import '../../../../../shared/services/api_service.dart';
import '../models/membership_model.dart';

class MembershipRemoteDataSource {
  Future<MembershipModel> fetch(String customerId) async {
    final payload = await ApiService.getCustomerMembershipBundle(customerId);
    return MembershipModel.fromJson(payload);
  }
}
