import 'package:flutter/foundation.dart';

import '../domain/repositories/admin_dashboard_repository.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController(this._repository);

  final AdminDashboardRepository _repository;

  AdminDashboardState _state = const AdminDashboardState();

  AdminDashboardState get state => _state;

  Future<void> load() async {
    if (_state.isLoading) {
      return;
    }

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final dashboard = await _repository.load();
      _state = _state.copyWith(
        isLoading: false,
        error: null,
        dashboard: dashboard,
      );
    } catch (error) {
      _state = _state.copyWith(isLoading: false, error: error);
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    _state = _state.copyWith(isRefreshing: true, error: null);
    notifyListeners();

    try {
      final dashboard = await _repository.load(forceRefresh: true);
      _state = _state.copyWith(
        isRefreshing: false,
        error: null,
        dashboard: dashboard,
      );
    } catch (error) {
      _state = _state.copyWith(isRefreshing: false, error: error);
    }

    notifyListeners();
  }
}
