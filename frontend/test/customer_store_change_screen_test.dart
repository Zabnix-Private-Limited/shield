import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/account/presentation/screens/store_change_screen.dart';

void main() {
  testWidgets('renders customer store-change history without an index error', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomerStoreChangeScreen(loadRequests: () async => [
          {
            'status': 'REJECTED',
            'reason': 'Relocated',
            'reviewReason': 'Requested pharmacy is not available in this area.',
            'requestedProvider': {'name': 'Hyper Pharmacy North'},
          },
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Hyper Pharmacy North'), findsOneWidget);
    expect(find.textContaining('Review note:'), findsOneWidget);
  });
}
