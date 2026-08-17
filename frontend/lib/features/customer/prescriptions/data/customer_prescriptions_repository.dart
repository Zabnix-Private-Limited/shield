import '../../../../shared/models/document.dart';
import '../../../../shared/services/api_service.dart';
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

  Future<Map<String, dynamic>> submitToPharmacy({
    required String documentId,
    required String providerId,
    String? customerNotes,
  }) => ApiService.submitCustomerPrescriptionToPharmacy(
    documentId: documentId,
    providerId: providerId,
    customerNotes: customerNotes,
  );

  Future<Map<String, dynamic>?> preferredPharmacy() async {
    try {
      return await ApiService.getPreferredProvider();
    } catch (_) {
      return null;
    }
  }
}
