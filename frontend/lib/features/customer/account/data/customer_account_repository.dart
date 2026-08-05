import '../../../../shared/services/api_service.dart';

class CustomerAccountRepository {
  const CustomerAccountRepository();

  Future<List<Map<String, dynamic>>> addresses() =>
      ApiService.getCustomerAddresses();
  Future<Map<String, dynamic>> saveAddress(
    Map<String, dynamic> value, {
    String? id,
  }) => ApiService.saveCustomerAddress(value, addressId: id);
  Future<void> removeAddress(String id) => ApiService.removeCustomerAddress(id);

  Future<List<Map<String, dynamic>>> dependents() =>
      ApiService.getCustomerDependents();
  Future<Map<String, dynamic>> saveDependent(
    Map<String, dynamic> value, {
    String? id,
  }) => ApiService.saveCustomerDependent(value, dependentId: id);
  Future<void> removeDependent(String id) =>
      ApiService.removeCustomerDependent(id);
}
