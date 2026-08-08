import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/models/document.dart';
import 'package:shield/features/customer/prescriptions/data/customer_prescriptions_repository.dart';
import 'package:shield/features/customer/prescriptions/presentation/customer_prescriptions_controller.dart';
import 'package:shield/features/customer/prescriptions/presentation/screens/customer_prescriptions_screen.dart';

class _FailingPrescriptionsRepository extends CustomerPrescriptionsRepository {
  @override
  Future<List<Document>> list() async =>
      throw StateError('Archive unavailable');
}

void main() {
  testWidgets('shows a retryable prescription archive failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerPrescriptionsScreen(
            controller: CustomerPrescriptionsController(
              repository: _FailingPrescriptionsRepository(),
            ),
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
