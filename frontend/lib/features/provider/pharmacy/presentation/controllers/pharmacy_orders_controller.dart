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
  final Set<String> _updatingItemKeys = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get friendlyError {
    if (_error == null || _error!.isEmpty || _error == 'null') {
      return 'Unable to process request right now. Please try again.';
    }
    final err = _error!;
    if (err.contains('DioException') ||
        err.contains('SocketException') ||
        err.contains('Failed host lookup')) {
      return 'Network connection issue. Please check your internet connection.';
    }
    if (err.contains('401') || err.contains('403')) {
      return 'Session expired or permission denied. Please re-authenticate.';
    }
    if (err.contains('404')) {
      return 'Selected order or item could not be found.';
    }
    if (err.contains('500')) {
      return 'Server error occurred while processing order fulfillment. Please retry.';
    }
    return err
        .replaceAll(RegExp(r'^Exception:\s*'), '')
        .replaceAll(RegExp(r'^DioException.*:\s*'), '');
  }

  String get activeStatusFilter => _activeStatusFilter;
  String get searchQuery => _searchQuery;
  PharmacyOrdersSummary? get summary => _summary;
  List<PharmacyOrderModel> get orders => _orders;
  PharmacyOrderModel? get selectedOrder => _selectedOrder;

  bool isOrderUpdating(String orderId) => _updatingOrderIds.contains(orderId);
  bool isItemUpdating(String orderId, String itemId) =>
      _updatingItemKeys.contains('$orderId:$itemId') ||
      _updatingOrderIds.contains(orderId);

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
      final results = await Future.wait<Object>([
        _repository.fetchSummary(),
        _repository.fetchOrders(
          status: _activeStatusFilter,
          query: _searchQuery,
        ),
      ]);
      _summary = results[0] as PharmacyOrdersSummary;
      _orders = results[1] as List<PharmacyOrderModel>;
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

  void _updateLocalOrder(String orderId, PharmacyOrderModel updated) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = updated;
    }
    if (_selectedOrder?.id == orderId) {
      _selectedOrder = updated;
    }
    notifyListeners();
  }

  Future<bool> updateOrderItemFulfillment({
    required String orderId,
    required String itemId,
    double? fulfillQuantity,
    String? stockStatus,
    String? decisionStatus,
    String? substituteName,
    double? substituteUnitPrice,
    String? decisionReason,
  }) async {
    final itemKey = '$orderId:$itemId';
    if (_updatingItemKeys.contains(itemKey)) {
      _error = 'Fulfillment decision update already in progress for this item.';
      return false;
    }
    _updatingItemKeys.add(itemKey);
    notifyListeners();

    try {
      final updated = await _repository.updateOrderItemFulfillment(
        orderId: orderId,
        itemId: itemId,
        fulfillQuantity: fulfillQuantity,
        stockStatus: stockStatus,
        decisionStatus: decisionStatus,
        substituteName: substituteName,
        substituteUnitPrice: substituteUnitPrice,
        decisionReason: decisionReason,
      );
      _updateLocalOrder(orderId, updated);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingItemKeys.remove(itemKey);
      notifyListeners();
    }
  }

  Future<bool> toggleChronicOrder({
    required String orderId,
    required bool isChronic,
  }) async {
    if (_updatingOrderIds.contains(orderId)) return false;
    _updatingOrderIds.add(orderId);
    notifyListeners();

    try {
      final updated = await _repository.toggleChronicOrder(
        orderId: orderId,
        isChronic: isChronic,
      );
      _updateLocalOrder(orderId, updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> savePharmacistNotes({
    required String orderId,
    required String notes,
  }) async {
    if (_updatingOrderIds.contains(orderId)) return false;
    _updatingOrderIds.add(orderId);
    notifyListeners();

    try {
      final updated = await _repository.savePharmacistNotes(
        orderId: orderId,
        notes: notes,
      );
      _updateLocalOrder(orderId, updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> uploadOrderInvoiceFile({
    required String orderId,
    required List<int> bytes,
    required String fileName,
  }) async {
    if (_updatingOrderIds.contains(orderId)) return false;
    _updatingOrderIds.add(orderId);
    notifyListeners();

    try {
      final updated = await _repository.uploadOrderInvoiceFile(
        orderId: orderId,
        bytes: bytes,
        fileName: fileName,
      );
      _updateLocalOrder(orderId, updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> removeOrderInvoice({required String orderId}) async {
    if (_updatingOrderIds.contains(orderId)) return false;
    _updatingOrderIds.add(orderId);
    notifyListeners();

    try {
      final updated = await _repository.removeOrderInvoice(orderId: orderId);
      _updateLocalOrder(orderId, updated);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> sendOrderInvoice({required String orderId}) async {
    if (_updatingOrderIds.contains(orderId)) return false;
    _updatingOrderIds.add(orderId);
    notifyListeners();

    try {
      final updated = await _repository.sendOrderInvoice(orderId: orderId);
      _updateLocalOrder(orderId, updated);
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
