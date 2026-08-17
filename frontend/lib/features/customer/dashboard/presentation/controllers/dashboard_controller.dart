import 'package:flutter/foundation.dart';

import '../../../../../shared/services/api_service.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  static final DashboardController _instance = DashboardController._internal();
  static DashboardController get instance => _instance;

  factory DashboardController({DashboardRepository? repository, String? customerId}) {
    if (repository != null || (customerId != null && customerId.trim().isNotEmpty)) {
      return DashboardController._internal(repository: repository, customerId: customerId);
    }
    return _instance;
  }

  DashboardController._internal({DashboardRepository? repository, this.customerId})
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

  Future<void> load({bool forceRefresh = false}) async {
    // If we already have in-memory dashboard and forceRefresh is false, keep displaying it instantly
    if (_dashboard != null && !forceRefresh) {
      _refreshInBackground();
      return;
    }

    _isLoading = _dashboard == null;
    _error = null;
    notifyListeners();

    DashboardModel? cached;
    try {
      cached = await _repository.loadCachedDashboard(_resolvedCustomerId);
      if (cached != null) {
        _dashboard = cached;
        _isLoading = false;
        notifyListeners();
      }
      _dashboard = await _repository.refreshDashboard(_resolvedCustomerId);
    } catch (error) {
      if (cached == null) {
        _error = error;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final updated = await _repository.refreshDashboard(_resolvedCustomerId);
      _dashboard = updated;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh() async {
    _error = null;
    notifyListeners();

    try {
      _dashboard = await _repository.refreshDashboard(_resolvedCustomerId);
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> invalidateCache() async {
    _dashboard = null;
    await _repository.invalidateCache(_resolvedCustomerId);
  }

  Future<void> submitMembershipApplication() async {
    await ApiService.submitCustomerMembershipApplication();
    await invalidateCache();
    await refresh();
  }
}
