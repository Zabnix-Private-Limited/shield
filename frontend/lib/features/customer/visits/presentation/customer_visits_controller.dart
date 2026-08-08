import 'package:flutter/foundation.dart';

import '../../../../shared/models/appointment.dart';
import '../data/customer_visits_repository.dart';

enum CustomerVisitsFilter { upcoming, completed, cancelled, all }

class CustomerVisitsController extends ChangeNotifier {
  CustomerVisitsController({CustomerVisitsRepository? repository})
    : _repository = repository ?? CustomerVisitsRepository();

  final CustomerVisitsRepository _repository;
  List<Appointment> appointments = const [];
  CustomerVisitsFilter filter = CustomerVisitsFilter.upcoming;
  bool isLoading = false;
  bool isMutating = false;
  Object? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      appointments = await _repository.list();
    } catch (value) {
      error = value;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(CustomerVisitsFilter value) {
    filter = value;
    notifyListeners();
  }

  List<Appointment> get visible => appointments.where((appointment) {
    switch (filter) {
      case CustomerVisitsFilter.upcoming:
        return appointment.status != AppointmentStatus.completed &&
            appointment.status != AppointmentStatus.cancelled;
      case CustomerVisitsFilter.completed:
        return appointment.status == AppointmentStatus.completed;
      case CustomerVisitsFilter.cancelled:
        return appointment.status == AppointmentStatus.cancelled;
      case CustomerVisitsFilter.all:
        return true;
    }
  }).toList()..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

  Future<bool> cancel(Appointment appointment) =>
      _mutate(() => _repository.cancel(appointment.id));

  Future<bool> reschedule(Appointment appointment, DateTime value) =>
      _mutate(() => _repository.reschedule(id: appointment.id, value: value));

  Future<bool> _mutate(Future<Appointment> Function() operation) async {
    if (isMutating) return false;
    isMutating = true;
    error = null;
    notifyListeners();
    try {
      await operation();
      await load();
      return true;
    } catch (value) {
      error = value;
      notifyListeners();
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }
}
