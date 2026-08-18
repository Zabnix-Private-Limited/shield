import 'package:flutter/foundation.dart';
import 'package:shield/features/provider/pharmacy/data/pharmacy_orders_repository.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';

class PharmacyOrdersController extends ChangeNotifier {
  PharmacyOrdersController._();
  static final PharmacyOrdersController instance = PharmacyOrdersController._();

  final PharmacyOrdersRepository _repository = PharmacyOrdersRepository();

  bool _isLoading = false;
  String? _error;
  String _activeStatusFilter = 'ALL';
  String _searchQuery = '';
  PharmacyOrdersSummary? _summary;
  List<PharmacyOrderModel> _orders = [];
  PharmacyOrderModel? _selectedOrder;
  final Set<String> _updatingOrderIds = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get activeStatusFilter => _activeStatusFilter;
  String get searchQuery => _searchQuery;
  PharmacyOrdersSummary? get summary => _summary;
  List<PharmacyOrderModel> get orders => _orders;
  PharmacyOrderModel? get selectedOrder => _selectedOrder;

  bool isOrderUpdating(String orderId) => _updatingOrderIds.contains(orderId);

  void selectOrder(PharmacyOrderModel? order) {
    _selectedOrder = order;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    if (_activeStatusFilter == status) return;
    _activeStatusFilter = status;
    loadOrders();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadOrders();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final summaryResult = await _repository.fetchSummary();
      _summary = summaryResult;

      final ordersResult = await _repository.fetchOrders(
        status: _activeStatusFilter,
        query: _searchQuery,
      );
      _orders = ordersResult;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus({
    required String orderId,
    required String nextStatus,
    String? cancellationReason,
  }) async {
    if (_updatingOrderIds.contains(orderId)) return false;

    _updatingOrderIds.add(orderId);
    notifyListeners();

    try {
      final updated = await _repository.updateOrderStatus(
        orderId: orderId,
        status: nextStatus,
        cancellationReason: cancellationReason,
      );

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updated;
      }
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updated;
      }

      await loadOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }
}
