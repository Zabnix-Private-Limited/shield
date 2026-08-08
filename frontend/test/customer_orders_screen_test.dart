import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/orders/domain/customer_order_summary.dart';
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

  testWidgets(
    'renders populated orders without horizontal overflow from 350 to 1200px',
    (tester) async {
      const widths = [350.0, 375.0, 390.0, 412.0, 448.0, 480.0, 768.0, 1200.0];
      const order = CustomerOrderSummary(
        id: '9',
        invoiceNumber: 'INV-VERY-LONG-REFERENCE-000009',
        orderStatus: 'PLACED',
        paymentStatus: 'PENDING',
        payableAmount: '1999.50',
        purchaseDate: null,
        itemCount: 12,
        providerName:
            'A pharmacy with a deliberately long visible business name',
      );

      for (final width in widths) {
        await tester.binding.setSurfaceSize(Size(width, 800));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomerOrdersScreen(loadOrders: () async => [order]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'width $width');
        expect(
          find.textContaining('INV-VERY-LONG-REFERENCE-000009'),
          findsOneWidget,
        );
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}
