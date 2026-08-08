import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/models/document.dart';
import 'package:shield/features/customer/documents/data/customer_documents_repository.dart';
import 'package:shield/features/customer/documents/presentation/customer_documents_controller.dart';
import 'package:shield/features/customer/documents/presentation/screens/customer_documents_screen.dart';

class _FailingDocumentsRepository extends CustomerDocumentsRepository {
  @override
  Future<List<Document>> list() async =>
      throw StateError('Archive unavailable');
}

void main() {
  testWidgets('shows a retryable archive failure without document data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerDocumentsScreen(
            controller: CustomerDocumentsController(
              repository: _FailingDocumentsRepository(),
            ),
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
