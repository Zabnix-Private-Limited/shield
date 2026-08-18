import 'package:flutter/foundation.dart';
import 'package:shield/features/provider/pharmacy/data/pharmacy_payments_repository.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_dashboard_model.dart';

class PharmacyDashboardController extends ChangeNotifier {
  PharmacyDashboardController._();
  static final PharmacyDashboardController instance =
      PharmacyDashboardController._();

  final PharmacyPaymentsRepository _repository = PharmacyPaymentsRepository();

  bool _isLoading = false;
  String? _error;
  PharmacyDashboardModel? _dashboardData;

  bool get isLoading => _isLoading;
  String? get error => _error;
  PharmacyDashboardModel? get dashboardData => _dashboardData;

  Future<void> loadDashboard({bool quiet = false}) async {
    if (!quiet || _dashboardData == null) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final res = await _repository.fetchPharmacyDashboard();
      _dashboardData = res;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
