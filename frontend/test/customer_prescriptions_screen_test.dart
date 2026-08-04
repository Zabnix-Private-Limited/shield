import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/prescriptions/presentation/screens/customer_prescriptions_screen.dart';

void main() {
  testWidgets('shows a retryable prescription archive failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerPrescriptionsScreen(
            loadDocuments: () async => throw StateError('Archive unavailable'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prescriptions unavailable'), findsOneWidget);
    expect(
      find.text('Your prescription history could not be loaded.'),
      findsOneWidget,
    );
    expect(find.text('No prescriptions yet'), findsNothing);
  });
}
