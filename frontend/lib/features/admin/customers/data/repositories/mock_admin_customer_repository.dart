import '../../domain/entities/admin_customer_summary.dart';
import '../../domain/repositories/admin_customer_repository.dart';

class MockAdminCustomerRepository implements AdminCustomerRepository {
  MockAdminCustomerRepository({
    List<AdminCustomerSummary> seed = const <AdminCustomerSummary>[],
  }) : _customers = List<AdminCustomerSummary>.from(seed);

  final List<AdminCustomerSummary> _customers;

  @override
  Future<void> createCustomer(AdminCustomerSummary customer) async {
    _customers.add(customer);
  }

  @override
  Future<List<AdminCustomerSummary>> listCustomers() async {
    return List<AdminCustomerSummary>.unmodifiable(_customers);
  }

  @override
  Future<void> updateCustomerStatus(String customerId, String status) async {
    final index = _customers.indexWhere((customer) => customer.id == customerId);
    if (index == -1) {
      throw StateError('Customer "$customerId" was not found in mock storage.');
    }
    _customers[index] = _customers[index].copyWith(status: status);
  }
}
