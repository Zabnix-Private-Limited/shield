import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/orders/domain/customer_order_summary.dart';

void main() {
  test('maps only returned purchase fields for customer order history', () {
    final order = CustomerOrderSummary.fromJson({
      'invoiceNumber': 'INV-42',
      'orderStatus': 'PLACED',
      'paymentStatus': 'PAID',
      'payableAmount': '249.50',
      'purchaseDate': '2026-08-04T10:00:00.000Z',
      'purchaseItems': [
        {'itemName': 'Demo wellness item'},
        {'itemName': 'Another demo item'},
      ],
      'provider': {'businessName': 'Demo Pharmacy'},
    });

    expect(order.invoiceNumber, 'INV-42');
    expect(order.orderStatus, 'PLACED');
    expect(order.payableAmount, '249.50');
    expect(order.itemCount, 2);
    expect(order.providerName, 'Demo Pharmacy');
  });
}
