import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/orders/presentation/screens/customer_orders_screen.dart';

void main() {
  testWidgets(
    'shows a retryable order-history failure instead of an empty list',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerOrdersScreen(
              loadOrders: () async => throw StateError('Orders unavailable'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Orders unavailable'), findsOneWidget);
      expect(
        find.text('Your pharmacy purchase history could not be loaded.'),
        findsOneWidget,
      );
      expect(find.text('No orders yet'), findsNothing);
    },
  );
}
