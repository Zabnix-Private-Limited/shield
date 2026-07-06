import 'package:flutter/foundation.dart';

import '../../../../../shared/services/api_service.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({DashboardRepository? repository, this.customerId})
    : _repository = repository ?? DashboardRepository();

  final DashboardRepository _repository;
  final String? customerId;

  bool _isLoading = false;
  Object? _error;
  DashboardModel? _dashboard;

  bool get isLoading => _isLoading;
  Object? get error => _error;
  DashboardModel? get dashboard => _dashboard;
  bool get hasData => _dashboard != null;

  String get _resolvedCustomerId =>
      ApiService.requireAuthenticatedCustomerId(customerId);

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboard = await _repository.loadDashboard(_resolvedCustomerId);
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _error = null;
    notifyListeners();

    try {
      _dashboard = await _repository.refreshDashboard(_resolvedCustomerId);
    } catch (error) {
      _error = error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> invalidateCache() async {
    await _repository.invalidateCache(_resolvedCustomerId);
  }
}
