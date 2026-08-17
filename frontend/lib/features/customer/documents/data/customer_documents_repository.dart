import 'dart:typed_data';

import '../../../../shared/models/document.dart';
import '../../../../shared/models/shield_role.dart';
import '../../../../shared/services/api_service.dart';

class CustomerDocumentsRepository {
  Future<List<Document>> list() async {
    try {
      return await ApiService.getDocuments(SHIELDRole.customer);
    } catch (e) {
      if (e is StateError || e.toString().contains('customer session')) {
        return const [];
      }
      rethrow;
    }
  }

  Future<Document> upload({
    required String fileName,
    required String documentType,
    required List<int> fileBytes,
    required String mimeType,
    required int fileSize,
  }) => ApiService.uploadCustomerDocument(
    fileName: fileName,
    documentType: documentType,
    fileBytes: Uint8List.fromList(fileBytes),
    mimeType: mimeType,
    fileSize: fileSize,
  );

  Future<String> viewerUrl(String documentId) =>
      ApiService.getDocumentDownloadUrl(documentId);
}
