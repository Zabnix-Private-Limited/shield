import 'package:flutter/foundation.dart';
import 'package:shield/features/provider/pharmacy/data/pharmacy_payment_details_repository.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_method_model.dart';

class PharmacyPaymentDetailsController extends ChangeNotifier {
  PharmacyPaymentDetailsController._();
  static final PharmacyPaymentDetailsController instance =
      PharmacyPaymentDetailsController._();

  final PharmacyPaymentDetailsRepository _repository =
      PharmacyPaymentDetailsRepository();

  bool _isLoading = false;
  String? _error;
  List<PharmacyPaymentMethodModel> _bankAccounts = [];
  List<PharmacyPaymentMethodModel> _upiMethods = [];
  final Set<String> _updatingMethodIds = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PharmacyPaymentMethodModel> get bankAccounts => _bankAccounts;
  List<PharmacyPaymentMethodModel> get upiMethods => _upiMethods;
  bool get isEmpty => _bankAccounts.isEmpty && _upiMethods.isEmpty;

  bool isMethodUpdating(String id) => _updatingMethodIds.contains(id);

  Future<void> loadPaymentDetails() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _repository.fetchPaymentDetails();
      _bankAccounts = res.bankAccounts;
      _upiMethods = res.upiMethods;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createBankAccount({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    String? branchName,
    String? displayLabel,
    bool isPrimary = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createBankAccount(
        accountHolderName: accountHolderName,
        bankName: bankName,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        branchName: branchName,
        displayLabel: displayLabel,
        isPrimary: isPrimary,
      );
      await loadPaymentDetails();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBankAccount({
    required String id,
    String? accountHolderName,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? branchName,
    String? displayLabel,
    bool? isPrimary,
  }) async {
    if (_updatingMethodIds.contains(id)) return false;
    _updatingMethodIds.add(id);
    notifyListeners();

    try {
      await _repository.updateBankAccount(
        id: id,
        accountHolderName: accountHolderName,
        bankName: bankName,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        branchName: branchName,
        displayLabel: displayLabel,
        isPrimary: isPrimary,
      );
      await loadPaymentDetails();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingMethodIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> createUpi({
    required String upiId,
    String? displayLabel,
    bool isPrimary = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createUpi(
        upiId: upiId,
        displayLabel: displayLabel,
        isPrimary: isPrimary,
      );
      await loadPaymentDetails();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUpi({
    required String id,
    String? upiId,
    String? displayLabel,
    bool? isPrimary,
  }) async {
    if (_updatingMethodIds.contains(id)) return false;
    _updatingMethodIds.add(id);
    notifyListeners();

    try {
      await _repository.updateUpi(
        id: id,
        upiId: upiId,
        displayLabel: displayLabel,
        isPrimary: isPrimary,
      );
      await loadPaymentDetails();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingMethodIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> uploadUpiQr({
    required String id,
    required List<int> bytes,
    required String filename,
  }) async {
    if (_updatingMethodIds.contains(id)) return false;
    _updatingMethodIds.add(id);
    notifyListeners();

    try {
      await _repository.uploadUpiQr(id: id, bytes: bytes, filename: filename);
      await loadPaymentDetails();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingMethodIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> removeUpiQr(String id) async {
    if (_updatingMethodIds.contains(id)) return false;
    _updatingMethodIds.add(id);
    notifyListeners();

    try {
      await _repository.removeUpiQr(id);
      await loadPaymentDetails();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingMethodIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> setPrimary(String id) async {
    if (_updatingMethodIds.contains(id)) return false;
    _updatingMethodIds.add(id);
    notifyListeners();

    try {
      await _repository.setPrimary(id);
      await loadPaymentDetails();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingMethodIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> toggleActive(String id, bool isActive) async {
    if (_updatingMethodIds.contains(id)) return false;
    _updatingMethodIds.add(id);
    notifyListeners();

    try {
      await _repository.toggleActive(id, isActive);
      await loadPaymentDetails();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _updatingMethodIds.remove(id);
      notifyListeners();
    }
  }
}
