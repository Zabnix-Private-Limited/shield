import 'package:flutter/foundation.dart';

import '../../services/data/models/customer_provider.dart';
import '../../../../shared/models/appointment.dart';
import '../data/customer_booking_repository.dart';

class CustomerBookingController extends ChangeNotifier {
  CustomerBookingController({CustomerBookingRepository? repository})
    : _repository = repository ?? CustomerBookingRepository();

  final CustomerBookingRepository _repository;
  CustomerProvider? provider;
  List<CustomerProvider> providers = const [];
  DateTime preferredDateTime = DateTime.now().add(const Duration(days: 1));
  String notes = '';
  bool isLoadingProvider = false;
  bool isSubmitting = false;
  Object? error;
  Appointment? completedAppointment;

  Future<void> restorePreselection(String? providerId) async {
    if (providerId == null || providerId.trim().isEmpty) return;
    isLoadingProvider = true;
    error = null;
    notifyListeners();
    try {
      provider = await _repository.provider(providerId.trim());
    } catch (value) {
      error = value;
    } finally {
      isLoadingProvider = false;
      notifyListeners();
    }
  }

  Future<void> searchProviders({String? query, String? type}) async {
    isLoadingProvider = true;
    error = null;
    notifyListeners();
    try {
      providers = await _repository.findProviders(
        query: query?.trim(),
        type: type,
      );
    } catch (value) {
      error = value;
    } finally {
      isLoadingProvider = false;
      notifyListeners();
    }
  }

  void selectProvider(CustomerProvider value) {
    provider = value;
    completedAppointment = null;
    error = null;
    notifyListeners();
  }

  void clearProvider() {
    provider = null;
    completedAppointment = null;
    error = null;
    notifyListeners();
  }

  void setPreferredDateTime(DateTime value) {
    preferredDateTime = value;
    completedAppointment = null;
    notifyListeners();
  }

  void setNotes(String value) => notes = value;

  Future<void> submit() async {
    if (isSubmitting || completedAppointment != null || provider == null) {
      return;
    }
    isSubmitting = true;
    error = null;
    completedAppointment = null;
    notifyListeners();
    try {
      completedAppointment = await _repository.submit(
        provider: provider!,
        preferredDateTime: preferredDateTime,
        notes: notes,
      );
    } catch (value) {
      error = value;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
