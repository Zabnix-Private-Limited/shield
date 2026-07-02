import 'package:flutter/foundation.dart';

import '../../data/agent_portal_repository.dart';

class AgentPortalController extends ChangeNotifier {
  AgentPortalController(this._repository);

  final AgentPortalRepository _repository;

  bool _loading = false;
  bool _customerLoading = false;
  bool _profileSaving = false;
  String? _error;
  Map<String, dynamic> _workspace = const <String, dynamic>{};
  Map<String, dynamic> _selectedCustomerWorkspace = const <String, dynamic>{};
  String? _selectedCustomerId;

  bool get isLoading => _loading;
  bool get isCustomerLoading => _customerLoading;
  bool get isProfileSaving => _profileSaving;
  String? get error => _error;
  Map<String, dynamic> get workspace => _workspace;
  Map<String, dynamic> get selectedCustomerWorkspace => _selectedCustomerWorkspace;
  String? get selectedCustomerId => _selectedCustomerId;

  Map<String, dynamic> get summary =>
      Map<String, dynamic>.from(workspace['summary'] ?? const {});
  Map<String, dynamic> get performance =>
      Map<String, dynamic>.from(workspace['performance'] ?? const {});
  Map<String, dynamic> get authProfile =>
      Map<String, dynamic>.from(workspace['authProfile'] ?? const {});
  Map<String, dynamic> get selectedCustomer =>
      Map<String, dynamic>.from(selectedCustomerWorkspace['customer'] ?? const {});

  List<Map<String, dynamic>> get customers => List<Map<String, dynamic>>.from(
        (workspace['customers'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get tasks => List<Map<String, dynamic>>.from(
        (workspace['tasks'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get notifications =>
      List<Map<String, dynamic>>.from(
        (workspace['notifications'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get recentActivity =>
      List<Map<String, dynamic>>.from(
        (workspace['recentActivity'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get upcomingAppointments =>
      List<Map<String, dynamic>>.from(
        (workspace['upcomingAppointments'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerTasks => List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['tasks'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerActivities =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['activities'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerAppointments =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['appointments'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerDocuments =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['documents'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerNotifications =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['notifications'] as List? ??
                const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  Future<void> ensureLoaded() async {
    if (_loading || workspace.isNotEmpty) {
      return;
    }
    await refreshWorkspace();
  }

  Future<void> refreshWorkspace() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _workspace = await _repository.getWorkspace();
      _selectedCustomerId ??=
          customers.isNotEmpty ? customers.first['id']?.toString() : null;
      if (_selectedCustomerId != null && _selectedCustomerWorkspace.isEmpty) {
        await selectCustomer(_selectedCustomerId!);
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectCustomer(String customerId) async {
    _selectedCustomerId = customerId;
    _customerLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedCustomerWorkspace = await _repository.getCustomerWorkspace(
        customerId,
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _customerLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCustomer(Map<String, dynamic> payload) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final created = await _repository.createCustomer(payload);
      await refreshWorkspace();
      final customer = created['customer'] as Map<String, dynamic>?;
      final customerId = customer?['id']?.toString();
      if (customerId != null && customerId.isNotEmpty) {
        await selectCustomer(customerId);
      }
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addFollowUpActivity({
    required String customerId,
    required String activityType,
    required String notes,
  }) async {
    await _repository.createFollowUpActivity(
      customerId: customerId,
      activityType: activityType,
      notes: notes,
    );
    await refreshWorkspace();
    await selectCustomer(customerId);
  }

  Future<void> scheduleFollowUp({
    required String customerId,
    required DateTime dueDate,
    required String notes,
  }) async {
    await _repository.createFollowUpTask(
      customerId: customerId,
      dueDate: dueDate,
      notes: notes,
    );
    await refreshWorkspace();
    await selectCustomer(customerId);
  }

  Future<void> updateFollowUpTask({
    required String taskId,
    required String customerId,
    required String status,
    String? notes,
  }) async {
    await _repository.updateFollowUpTask(
      taskId: taskId,
      status: status,
      notes: notes,
    );
    await refreshWorkspace();
    await selectCustomer(customerId);
  }

  Future<void> createAppointment({
    required String customerId,
    required String providerId,
    required String appointmentType,
    required DateTime appointmentDate,
    String? remarks,
  }) async {
    await _repository.createAppointment(
      customerId: customerId,
      providerId: providerId,
      appointmentType: appointmentType,
      appointmentDate: appointmentDate,
      remarks: remarks,
    );
    await refreshWorkspace();
    await selectCustomer(customerId);
  }

  Future<void> updateCurrentProfile(Map<String, dynamic> payload) async {
    _profileSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.updateCurrentProfile(payload);
      final profile = await _repository.getCurrentProfile();
      _workspace = <String, dynamic>{..._workspace, 'authProfile': profile};
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _profileSaving = false;
      notifyListeners();
    }
  }
}
