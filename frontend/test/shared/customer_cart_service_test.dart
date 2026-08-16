import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/services/customer_cart_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartItem Model', () {
    test('calculates line total accurately', () {
      const item = CartItem(
        productId: '101',
        productName: 'Vitamin C 500mg',
        brand: 'HealthPlus',
        unitPrice: 250.0,
        quantity: 3,
      );

      expect(item.lineTotal, 750.0);
      expect(item.toJson()['productId'], '101');
    });

    test('serializes and deserializes from JSON', () {
      final json = {
        'productId': '202',
        'productName': 'Omega 3 Fish Oil',
        'brand': 'NutraLife',
        'unitPrice': 450.0,
        'quantity': 2,
      };

      final item = CartItem.fromJson(json);
      expect(item.productId, '202');
      expect(item.productName, 'Omega 3 Fish Oil');
      expect(item.unitPrice, 450.0);
      expect(item.quantity, 2);
      expect(item.lineTotal, 900.0);
    });
  });

  group('CustomerCartService Calculations', () {
    test('starts empty with zero subtotal and item count', () {
      final cart = CustomerCartService.instance;
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.subtotal, 0.0);
    });
  });
}
