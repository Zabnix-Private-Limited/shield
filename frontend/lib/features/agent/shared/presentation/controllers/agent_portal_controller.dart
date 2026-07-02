import 'package:flutter/foundation.dart';

import '../../data/agent_portal_repository.dart';

class AgentPortalController extends ChangeNotifier {
  AgentPortalController(this._repository);

  final AgentPortalRepository _repository;

  bool _loading = false;
  bool _customerLoading = false;
  bool _profileSaving = false;
  bool _saving = false;
  String? _error;
  Map<String, dynamic> _workspace = const <String, dynamic>{};
  Map<String, dynamic> _selectedCustomerWorkspace = const <String, dynamic>{};
  String? _selectedCustomerId;
  List<Map<String, dynamic>> _providers = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _businesses = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _membershipTypes = const <Map<String, dynamic>>[];

  bool get isLoading => _loading;
  bool get isCustomerLoading => _customerLoading;
  bool get isProfileSaving => _profileSaving;
  bool get isSaving => _saving;
  String? get error => _error;
  Map<String, dynamic> get workspace => _workspace;
  Map<String, dynamic> get selectedCustomerWorkspace => _selectedCustomerWorkspace;
  String? get selectedCustomerId => _selectedCustomerId;
  List<Map<String, dynamic>> get providers => _providers;
  List<Map<String, dynamic>> get businesses => _businesses;
  List<Map<String, dynamic>> get membershipTypes => _membershipTypes;

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

  List<Map<String, dynamic>> get customerFamilyDetails =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['familyDetails'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerPurchases =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['purchases'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerMedicalRecords =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['medicalRecords'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerTimeline =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['timeline'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  Map<String, dynamic> get customerMembership =>
      Map<String, dynamic>.from(selectedCustomerWorkspace['membership'] ?? const {});

  Map<String, dynamic> get customerWallet =>
      Map<String, dynamic>.from(selectedCustomerWorkspace['wallet'] ?? const {});

  Map<String, dynamic> get customerReferralSummary => Map<String, dynamic>.from(
        selectedCustomerWorkspace['referralSummary'] ?? const {},
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
      await _ensureReferenceData();
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

  Future<void> _ensureReferenceData() async {
    if (_providers.isNotEmpty &&
        _businesses.isNotEmpty &&
        _membershipTypes.isNotEmpty) {
      return;
    }

    try {
      final providers = await _repository.getProviders();
      final businesses = await _repository.getBusinesses();
      final membershipTypes = await _repository.getMembershipTypes();
      _providers = providers;
      _businesses = businesses;
      _membershipTypes = membershipTypes;
    } catch (_) {
      // Keep the workspace usable even if optional reference lookups fail.
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
    _saving = true;
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
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomer({
    required String customerId,
    required Map<String, dynamic> payload,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.updateCustomer(customerId, payload);
      await refreshWorkspace();
      await selectCustomer(customerId);
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _saving = false;
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

  Future<void> confirmAppointment({
    required String appointmentId,
    required String customerId,
  }) async {
    await _repository.confirmAppointment(appointmentId);
    await refreshWorkspace();
    await selectCustomer(customerId);
  }

  Future<void> cancelAppointment({
    required String appointmentId,
    required String customerId,
  }) async {
    await _repository.cancelAppointment(appointmentId);
    await refreshWorkspace();
    await selectCustomer(customerId);
  }

  Future<void> rescheduleAppointment({
    required String appointmentId,
    required String customerId,
    required DateTime appointmentDate,
    String? remarks,
  }) async {
    await _repository.rescheduleAppointment(
      appointmentId: appointmentId,
      appointmentDate: appointmentDate,
      remarks: remarks,
    );
    await refreshWorkspace();
    await selectCustomer(customerId);
  }

  Future<void> uploadCustomerDocument({
    required String customerId,
    required String fileName,
    required String documentType,
    required Uint8List fileBytes,
    required String mimeType,
    required int fileSize,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.uploadCustomerDocument(
        customerId: customerId,
        fileName: fileName,
        documentType: documentType,
        fileBytes: fileBytes,
        mimeType: mimeType,
        fileSize: fileSize,
      );
      await refreshWorkspace();
      await selectCustomer(customerId);
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _repository.markNotificationRead(notificationId);
    await refreshWorkspace();
    if (_selectedCustomerId != null) {
      await selectCustomer(_selectedCustomerId!);
    }
  }

  Future<void> markAllNotificationsRead({String? customerId}) async {
    await _repository.markAllNotificationsRead(customerId: customerId);
    await refreshWorkspace();
    if (_selectedCustomerId != null) {
      await selectCustomer(_selectedCustomerId!);
    }
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
