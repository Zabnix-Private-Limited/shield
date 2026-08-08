import '../../../../shared/models/document.dart';
import '../../documents/data/customer_documents_repository.dart';

class CustomerPrescriptionsRepository {
  CustomerPrescriptionsRepository({CustomerDocumentsRepository? documents})
    : _documents = documents ?? CustomerDocumentsRepository();

  final CustomerDocumentsRepository _documents;

  Future<List<Document>> list() async => (await _documents.list())
      .where((document) => document.type == DocumentType.prescription)
      .toList();

  Future<String> viewerUrl(String documentId) =>
      _documents.viewerUrl(documentId);
}
