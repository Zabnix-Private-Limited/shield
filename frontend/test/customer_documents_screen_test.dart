import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/documents/presentation/screens/customer_documents_screen.dart';

void main() {
  testWidgets('shows a retryable archive failure without document data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerDocumentsScreen(
            loadDocuments: () async => throw StateError('Archive unavailable'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Documents unavailable'), findsOneWidget);
    expect(
      find.text('Your document archive could not be loaded.'),
      findsOneWidget,
    );
    expect(find.text('No documents yet'), findsNothing);
  });
}
