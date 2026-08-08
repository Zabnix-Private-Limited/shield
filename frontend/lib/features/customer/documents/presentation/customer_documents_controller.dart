import 'package:flutter/foundation.dart';

import '../../../../shared/models/document.dart';
import '../data/customer_documents_repository.dart';

class CustomerDocumentsController extends ChangeNotifier {
  CustomerDocumentsController({CustomerDocumentsRepository? repository})
    : _repository = repository ?? CustomerDocumentsRepository();

  final CustomerDocumentsRepository _repository;
  List<Document> documents = const [];
  DocumentType? selectedType;
  String query = '';
  bool isLoading = false;
  bool isUploading = false;
  Object? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      documents = await _repository.list();
    } catch (value) {
      error = value;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setType(DocumentType? value) {
    selectedType = value;
    notifyListeners();
  }

  void setQuery(String value) {
    query = value.trim();
    notifyListeners();
  }

  List<Document> get visible {
    final normalizedQuery = query.toLowerCase();
    return documents.where((document) {
      final matchesType = selectedType == null || document.type == selectedType;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          document.fileName.toLowerCase().contains(normalizedQuery) ||
          document.typeLabel.toLowerCase().contains(normalizedQuery);
      return matchesType && matchesQuery;
    }).toList();
  }

  Future<Document?> upload({
    required String fileName,
    required String documentType,
    required List<int> fileBytes,
    required String mimeType,
    required int fileSize,
  }) async {
    if (isUploading) return null;
    isUploading = true;
    error = null;
    notifyListeners();
    try {
      final document = await _repository.upload(
        fileName: fileName,
        documentType: documentType,
        fileBytes: fileBytes,
        mimeType: mimeType,
        fileSize: fileSize,
      );
      documents = [
        document,
        ...documents.where((item) => item.id != document.id),
      ];
      return document;
    } catch (value) {
      error = value;
      return null;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<String> viewerUrl(Document document) =>
      _repository.viewerUrl(document.id);
}
