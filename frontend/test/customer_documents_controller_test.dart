import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/documents/data/customer_documents_repository.dart';
import 'package:shield/features/customer/documents/presentation/customer_documents_controller.dart';
import 'package:shield/shared/models/document.dart';

class _DocumentsRepository extends CustomerDocumentsRepository {
  _DocumentsRepository(this.items);

  final List<Document> items;

  @override
  Future<List<Document>> list() async => items;

  @override
  Future<Document> upload({
    required String fileName,
    required String documentType,
    required List<int> fileBytes,
    required String mimeType,
    required int fileSize,
  }) async =>
      _document(id: 'new', fileName: fileName, type: DocumentType.prescription);
}

Document _document({
  required String id,
  required String fileName,
  required DocumentType type,
}) => Document(
  id: id,
  uuid: 'uuid-$id',
  customerId: '',
  fileName: fileName,
  storagePath: '',
  type: type,
  status: DocumentStatus.uploaded,
  uploadedAt: DateTime.utc(2026, 8, 8),
);

void main() {
  test(
    'filters the customer-safe archive by category and trimmed search',
    () async {
      final controller = CustomerDocumentsController(
        repository: _DocumentsRepository([
          _document(
            id: '1',
            fileName: 'Blood report.pdf',
            type: DocumentType.labReport,
          ),
          _document(
            id: '2',
            fileName: 'Prescription.pdf',
            type: DocumentType.prescription,
          ),
        ]),
      );

      await controller.load();
      controller.setType(DocumentType.labReport);
      controller.setQuery('  blood  ');

      expect(controller.visible.map((document) => document.id), ['1']);
    },
  );

  test('prevents duplicate uploads while one upload is active', () async {
    final controller = CustomerDocumentsController(
      repository: _DocumentsRepository(const []),
    );

    final first = controller.upload(
      fileName: 'prescription.pdf',
      documentType: 'PRESCRIPTION',
      fileBytes: const [1, 2],
      mimeType: 'application/pdf',
      fileSize: 2,
    );
    final duplicate = controller.upload(
      fileName: 'prescription.pdf',
      documentType: 'PRESCRIPTION',
      fileBytes: const [1, 2],
      mimeType: 'application/pdf',
      fileSize: 2,
    );

    expect(await first, isNotNull);
    expect(await duplicate, isNull);
  });
}
