import 'package:flutter/foundation.dart';

import '../../../../shared/models/document.dart';
import '../data/customer_prescriptions_repository.dart';

class CustomerPrescriptionsController extends ChangeNotifier {
  CustomerPrescriptionsController({CustomerPrescriptionsRepository? repository})
    : _repository = repository ?? CustomerPrescriptionsRepository();

  final CustomerPrescriptionsRepository _repository;
  List<Document> prescriptions = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  Object? error;
  Map<String, dynamic>? submittedRequest;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      prescriptions = await _repository.list();
    } catch (value) {
      error = value;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> viewerUrl(Document document) =>
      _repository.viewerUrl(document.id);

  Future<bool> submitToPharmacy({
    required Document prescription,
    required String providerId,
    String? customerNotes,
  }) async {
    if (isSubmitting || providerId.trim().isEmpty) return false;
    isSubmitting = true;
    error = null;
    submittedRequest = null;
    notifyListeners();
    try {
      submittedRequest = await _repository.submitToPharmacy(
        documentId: prescription.id,
        providerId: providerId,
        customerNotes: customerNotes,
      );
      return true;
    } catch (value) {
      error = value;
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
