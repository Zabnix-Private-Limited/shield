import 'package:flutter/foundation.dart';

import '../../../../shared/models/document.dart';
import '../data/customer_prescriptions_repository.dart';

class CustomerPrescriptionsController extends ChangeNotifier {
  CustomerPrescriptionsController({CustomerPrescriptionsRepository? repository})
    : _repository = repository ?? CustomerPrescriptionsRepository();

  final CustomerPrescriptionsRepository _repository;
  List<Document> prescriptions = const [];
  bool isLoading = false;
  Object? error;

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
}
