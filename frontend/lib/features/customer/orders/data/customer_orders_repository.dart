import '../../../../shared/services/api_service.dart';
import '../domain/customer_order_summary.dart';

class CustomerOrdersRepository {
  const CustomerOrdersRepository();

  Future<List<CustomerOrderSummary>> listOrders() async {
    final orders = await ApiService.getCustomerOrders();
    return orders.map(CustomerOrderSummary.fromJson).toList();
  }

  Future<CustomerOrderDetails> getOrder(String orderId) async {
    final order = await ApiService.getCustomerOrder(orderId);
    return CustomerOrderDetails.fromJson(order);
  }
}
