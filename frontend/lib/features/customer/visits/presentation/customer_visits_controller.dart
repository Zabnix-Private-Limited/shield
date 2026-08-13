import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../shared/models/appointment.dart';
import '../data/customer_visits_repository.dart';

enum CustomerVisitsFilter { upcoming, completed, cancelled, all }

enum CustomerVisitsErrorKind { unavailable, offline, unauthorized, malformed }

class CustomerVisitsController extends ChangeNotifier {
  CustomerVisitsController({CustomerVisitsRepository? repository})
    : _repository = repository ?? CustomerVisitsRepository();

  final CustomerVisitsRepository _repository;
  List<Appointment> appointments = const [];
  CustomerVisitsFilter filter = CustomerVisitsFilter.upcoming;
  bool isLoading = false;
  bool isMutating = false;
  Object? error;
  CustomerVisitsErrorKind? errorKind;
  int _loadGeneration = 0;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    isLoading = true;
    error = null;
    errorKind = null;
    notifyListeners();
    try {
      final loadedAppointments = await _repository.list();
      if (generation != _loadGeneration) return;
      appointments = loadedAppointments;
    } catch (value) {
      if (generation != _loadGeneration) return;
      error = value;
      errorKind = _classifyError(value);
    }
    if (generation != _loadGeneration) return;
    isLoading = false;
    notifyListeners();
  }

  CustomerVisitsErrorKind _classifyError(Object value) {
    if (value is FormatException) return CustomerVisitsErrorKind.malformed;
    if (value is DioException) {
      final status = value.response?.statusCode;
      if (status == 401 || status == 403) {
        return CustomerVisitsErrorKind.unauthorized;
      }
      if (value.type == DioExceptionType.connectionError ||
          value.type == DioExceptionType.connectionTimeout ||
          value.type == DioExceptionType.receiveTimeout ||
          value.type == DioExceptionType.sendTimeout) {
        return CustomerVisitsErrorKind.offline;
      }
    }
    return CustomerVisitsErrorKind.unavailable;
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
