import '../entities/admin_customer_summary.dart';

abstract class AdminCustomerRepository {
  Future<List<AdminCustomerSummary>> listCustomers();

  Future<void> createCustomer(AdminCustomerSummary customer);

  Future<void> updateCustomerStatus(String customerId, String status);
}
