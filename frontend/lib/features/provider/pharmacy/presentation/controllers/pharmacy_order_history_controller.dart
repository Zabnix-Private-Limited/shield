import 'package:flutter/foundation.dart';
import 'package:shield/features/provider/pharmacy/data/pharmacy_order_history_repository.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_history_model.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';

class PharmacyOrderHistoryController extends ChangeNotifier {
  PharmacyOrderHistoryController._();
  static final PharmacyOrderHistoryController instance =
      PharmacyOrderHistoryController._();

  final PharmacyOrderHistoryRepository _repository =
      PharmacyOrderHistoryRepository();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _activeStatus = 'ALL_HISTORY';
  String _activeDatePreset = 'ALL_TIME';
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;

  List<PharmacyOrderModel> _orders = [];
  PharmacyOrderHistorySummary? _summary;
  PharmacyOrderModel? _selectedOrderDetail;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get activeStatus => _activeStatus;
  String get activeDatePreset => _activeDatePreset;
  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _currentPage < _totalPages;

  List<PharmacyOrderModel> get orders => _orders;
  PharmacyOrderHistorySummary? get summary => _summary;
  PharmacyOrderModel? get selectedOrderDetail => _selectedOrderDetail;
  bool get isEmpty => _orders.isEmpty;

  void setActiveStatus(String status) {
    if (_activeStatus == status) return;
    _activeStatus = status;
    _currentPage = 1;
    loadHistory();
  }

  void setActiveDatePreset(String preset) {
    if (_activeDatePreset == preset) return;
    _activeDatePreset = preset;
    _currentPage = 1;
    loadHistory();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    loadHistory();
  }

  (String?, String?) _resolveDateRange() {
    final now = DateTime.now();
    String formatDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    switch (_activeDatePreset) {
      case 'TODAY':
        final todayStr = formatDate(now);
        return (todayStr, todayStr);
      case 'LAST_7_DAYS':
        final start = now.subtract(const Duration(days: 7));
        return (formatDate(start), formatDate(now));
      case 'LAST_30_DAYS':
        final start = now.subtract(const Duration(days: 30));
        return (formatDate(start), formatDate(now));
      case 'THIS_MONTH':
        final start = DateTime(now.year, now.month, 1);
        return (formatDate(start), formatDate(now));
      default:
        return (null, null);
    }
  }

  Future<void> loadHistory({bool quiet = false}) async {
    if (!quiet || _orders.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    final (from, to) = _resolveDateRange();

    try {
      final res = await _repository.fetchOrderHistory(
        status: _activeStatus,
        search: _searchQuery,
        from: from,
        to: to,
        page: 1,
        pageSize: 20,
      );
      _orders = res.orders;
      _summary = res.summary;
      _currentPage = res.pagination.page;
      _totalPages = res.pagination.totalPages;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    final (from, to) = _resolveDateRange();
    final nextPage = _currentPage + 1;

    try {
      final res = await _repository.fetchOrderHistory(
        status: _activeStatus,
        search: _searchQuery,
        from: from,
        to: to,
        page: nextPage,
        pageSize: 20,
      );
      _orders.addAll(res.orders);
      _summary = res.summary;
      _currentPage = res.pagination.page;
      _totalPages = res.pagination.totalPages;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadOrderDetail(String id) async {
    try {
      final detail = await _repository.fetchOrderHistoryDetail(id);
      _selectedOrderDetail = detail;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
