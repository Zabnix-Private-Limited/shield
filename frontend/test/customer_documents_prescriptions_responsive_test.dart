import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/documents/data/customer_documents_repository.dart';
import 'package:shield/features/customer/documents/presentation/customer_documents_controller.dart';
import 'package:shield/features/customer/documents/presentation/screens/customer_documents_screen.dart';
import 'package:shield/features/customer/prescriptions/data/customer_prescriptions_repository.dart';
import 'package:shield/features/customer/prescriptions/presentation/customer_prescriptions_controller.dart';
import 'package:shield/features/customer/prescriptions/presentation/screens/customer_prescriptions_screen.dart';
import 'package:shield/shared/models/document.dart';

final _longPrescription = Document(
  id: '1',
  uuid: 'document-1',
  customerId: '',
  fileName:
      'A very long synthetic prescription filename that must wrap safely on narrow customer screens.pdf',
  storagePath: '',
  fileSize: 1024,
  mimeType: 'application/pdf',
  type: DocumentType.prescription,
  status: DocumentStatus.uploaded,
  uploadedAt: DateTime.utc(2026, 8, 8),
);

class _DocumentRepository extends CustomerDocumentsRepository {
  @override
  Future<List<Document>> list() async => [_longPrescription];
}

class _PrescriptionRepository extends CustomerPrescriptionsRepository {
  @override
  Future<List<Document>> list() async => [_longPrescription];

  @override
  Future<Map<String, dynamic>?> preferredPharmacy() async => {
    'id': '2',
    'providerName': 'Synthetic Pharmacy',
  };
}

void main() {
  const widths = [350.0, 375.0, 390.0, 412.0, 448.0, 480.0, 768.0, 1200.0];

  testWidgets('documents and prescriptions fit every required width', (
    tester,
  ) async {
    for (final width in widths) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  CustomerDocumentsScreen(
                    controller: CustomerDocumentsController(
                      repository: _DocumentRepository(),
                    ),
                  ),
                  CustomerPrescriptionsScreen(
                    controller: CustomerPrescriptionsController(
                      repository: _PrescriptionRepository(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
