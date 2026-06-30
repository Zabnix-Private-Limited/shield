import 'package:flutter/foundation.dart';

import '../../../../../shared/models/appointment.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/document.dart';
import '../../data/provider_portal_repository.dart';

class ProviderPortalController extends ChangeNotifier {
  ProviderPortalController(this._repository);

  final ProviderPortalRepository _repository;

  bool _loading = false;
  bool _workspaceLoaded = false;
  bool _customerLoading = false;
  bool _settingsLoading = false;
  String? _error;
  String? _selectedCustomerId;
  Map<String, dynamic>? _workspace;
  Map<String, dynamic>? _authProfile;
  Customer? _selectedCustomer;
  Map<String, dynamic>? _selectedWallet;
  Map<String, dynamic>? _selectedMembership;
  List<Document> _selectedDocuments = const <Document>[];
  List<Appointment> _selectedAppointments = const <Appointment>[];
  List<Map<String, dynamic>> _sessions = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _loginHistory = const <Map<String, dynamic>>[];

  bool get isLoading => _loading;
  bool get isWorkspaceLoaded => _workspaceLoaded;
  bool get isCustomerLoading => _customerLoading;
  bool get isSettingsLoading => _settingsLoading;
  String? get error => _error;
  Map<String, dynamic> get workspace => _workspace ?? const <String, dynamic>{};
  Map<String, dynamic> get authProfile =>
      _authProfile ?? const <String, dynamic>{};
  String? get selectedCustomerId => _selectedCustomerId;
  Customer? get selectedCustomer => _selectedCustomer;
  Map<String, dynamic>? get selectedWallet => _selectedWallet;
  Map<String, dynamic>? get selectedMembership => _selectedMembership;
  List<Document> get selectedDocuments => _selectedDocuments;
  List<Appointment> get selectedAppointments => _selectedAppointments;
  List<Map<String, dynamic>> get sessions => _sessions;
  List<Map<String, dynamic>> get loginHistory => _loginHistory;

  List<Map<String, dynamic>> get providers =>
      List<Map<String, dynamic>>.from(workspace['providers'] ?? const []);
  List<Map<String, dynamic>> get customers =>
      List<Map<String, dynamic>>.from(workspace['customers'] ?? const []);
  Map<String, dynamic> get summary =>
      Map<String, dynamic>.from(workspace['summary'] ?? const {});
  Map<String, dynamic> get queues =>
      Map<String, dynamic>.from(workspace['queues'] ?? const {});
  List<Map<String, dynamic>> get appointmentQueue =>
      List<Map<String, dynamic>>.from(queues['appointments'] ?? const []);
  List<Map<String, dynamic>> get billingQueue =>
      List<Map<String, dynamic>>.from(queues['billing'] ?? const []);

  Future<void> ensureLoaded() async {
    if (_loading || _workspaceLoaded) {
      return;
    }
    await refreshWorkspace();
  }

  Future<void> refreshWorkspace() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getWorkspace(),
        _repository.getAuthenticatedProfile(),
      ]);
      _workspace = results[0];
      _authProfile = results[1];
      _workspaceLoaded = true;
      _selectedCustomerId ??= customers.isNotEmpty
          ? customers.first['id']?.toString()
          : null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }

    if (_selectedCustomerId != null) {
      await selectCustomer(_selectedCustomerId!);
    }
  }

  Future<void> selectCustomer(String customerId) async {
    if (_customerLoading && _selectedCustomerId == customerId) {
      return;
    }

    _selectedCustomerId = customerId;
    _customerLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCustomerProfile(customerId),
        _repository.getCustomerWallet(customerId),
        _repository.getCustomerMembership(customerId),
        _repository.getCustomerDocuments(customerId),
        _repository.getCustomerAppointments(customerId),
      ]);
      _selectedCustomer = results[0] as Customer;
      _selectedWallet = results[1] as Map<String, dynamic>;
      _selectedMembership = results[2] as Map<String, dynamic>;
      _selectedDocuments = results[3] as List<Document>;
      _selectedAppointments = results[4] as List<Appointment>;
    } catch (error) {
      _error = error.toString();
    } finally {
      _customerLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettingsData() async {
    if (_settingsLoading) {
      return;
    }
    _settingsLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getSessions(),
        _repository.getLoginHistory(),
      ]);
      _sessions = results[0];
      _loginHistory = results[1];
    } catch (error) {
      _error = error.toString();
    } finally {
      _settingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> revokeOwnedSession(String sessionId) async {
    await _repository.revokeSession(sessionId);
    await loadSettingsData();
  }
}
