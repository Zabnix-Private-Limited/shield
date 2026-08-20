import 'package:flutter/foundation.dart';
import 'package:shield/features/provider/pharmacy/data/pharmacy_payments_repository.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_request_model.dart';

class PharmacyPaymentsController extends ChangeNotifier {
  PharmacyPaymentsController._();
  static final PharmacyPaymentsController instance =
      PharmacyPaymentsController._();

  final PharmacyPaymentsRepository _repository = PharmacyPaymentsRepository();

  bool _isLoading = false;
  String? _error;
  String _activeStatus = 'ALL';
  String _searchQuery = '';
  List<PharmacyPaymentRequestModel> _payments = [];
  PharmacyPaymentRequestModel? _selectedPaymentDetail;
  final Set<String> _mutatingIds = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get activeStatus => _activeStatus;
  String get searchQuery => _searchQuery;
  List<PharmacyPaymentRequestModel> get payments => _payments;
  PharmacyPaymentRequestModel? get selectedPaymentDetail => _selectedPaymentDetail;
  bool get isEmpty => _payments.isEmpty;

  bool isMutating(String id) => _mutatingIds.contains(id);

  void setActiveStatus(String status) {
    if (_activeStatus == status) return;
    _activeStatus = status;
    loadPayments();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadPayments();
  }

  Future<void> loadPayments({bool quiet = false}) async {
    if (!quiet) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final res = await _repository.fetchPayments(
        status: _activeStatus,
        search: _searchQuery,
      );
      _payments = res;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPaymentDetail(String id) async {
    try {
      final detail = await _repository.fetchPaymentDetail(id);
      _selectedPaymentDetail = detail;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> approvePayment(String id) async {
    if (_mutatingIds.contains(id)) return false;
    _mutatingIds.add(id);
    notifyListeners();

    try {
      await _repository.approvePayment(id);
      await loadPayments(quiet: true);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _mutatingIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> rejectPayment(String id, String rejectionReason) async {
    if (_mutatingIds.contains(id)) return false;
    _mutatingIds.add(id);
    notifyListeners();

    try {
      await _repository.rejectPayment(id, rejectionReason);
      await loadPayments(quiet: true);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _mutatingIds.remove(id);
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    try {
      return await _repository.searchCustomers(query);
    } catch (e) {
      debugPrint('Error searching customers: $e');
      return [];
    }
  }

  Future<bool> submitCounterPayment({
    required String customerId,
    required double amount,
    required String paymentChannel,
    String? referenceNumber,
    String? customerNotes,
    bool autoApprove = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.submitManualPayment(
        customerId: customerId,
        amount: amount,
        paymentChannel: paymentChannel,
        referenceNumber: referenceNumber,
        customerNotes: customerNotes,
        autoApprove: autoApprove,
      );
      await loadPayments(quiet: true);
      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
