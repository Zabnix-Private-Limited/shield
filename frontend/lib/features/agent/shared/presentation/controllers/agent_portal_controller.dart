import 'package:flutter/foundation.dart';

import '../../../../../shared/services/internal_auth_session.dart';
import '../../data/agent_portal_repository.dart';

class AgentPortalController extends ChangeNotifier {
  AgentPortalController(this._repository);

  final AgentPortalRepository _repository;

  bool _loading = false;
  bool _customerLoading = false;
  bool _profileSaving = false;
  bool _settingsLoading = false;
  bool _saving = false;
  bool _referenceDataLoading = false;
  String? _error;
  String? _providerLookupError;
  Map<String, dynamic> _workspace = const <String, dynamic>{};
  Map<String, dynamic> _selectedCustomerWorkspace = const <String, dynamic>{};
  Map<String, dynamic> _reportRegistry = const <String, dynamic>{};
  String? _selectedCustomerId;
  List<Map<String, dynamic>> _providers = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _businesses = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _membershipTypes = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _sessions = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _loginHistory = const <Map<String, dynamic>>[];
  Map<String, dynamic> _customerListPage = const <String, dynamic>{};
  Future<void>? _selectedCustomerRequest;

  bool get isLoading => _loading;
  bool get isCustomerLoading => _customerLoading;
  bool get isProfileSaving => _profileSaving;
  bool get isSettingsLoading => _settingsLoading;
  bool get isSaving => _saving;
  bool get isReferenceDataLoading => _referenceDataLoading;
  String? get error => _error;
  String? get providerLookupError => _providerLookupError;
  Map<String, dynamic> get workspace => _workspace;
  Map<String, dynamic> get selectedCustomerWorkspace =>
      _selectedCustomerWorkspace;
  Map<String, dynamic> get reportRegistry => _reportRegistry;
  String? get selectedCustomerId => _selectedCustomerId;
  List<Map<String, dynamic>> get providers => _providers;
  List<Map<String, dynamic>> get businesses => _businesses;
  List<Map<String, dynamic>> get membershipTypes => _membershipTypes;
  List<Map<String, dynamic>> get sessions => _sessions;
  List<Map<String, dynamic>> get loginHistory => _loginHistory;
  Map<String, dynamic> get customerListPage => _customerListPage;

  Map<String, dynamic> get summary =>
      selectedCustomerWorkspace['summary'] is Map<String, dynamic>
          ? selectedCustomerWorkspace['summary'] as Map<String, dynamic>
          : const <String, dynamic>{};
  Map<String, dynamic> get performance =>
      Map<String, dynamic>.from(workspace['performance'] ?? const {});
  Map<String, dynamic> get authProfile =>
      Map<String, dynamic>.from(workspace['authProfile'] ?? const {});
  Map<String, dynamic> get agentSettings =>
      Map<String, dynamic>.from(workspace['agentSettings'] ?? const {});
  Map<String, dynamic> get selectedCustomer =>
      selectedCustomerWorkspace['customer'] is Map<String, dynamic>
          ? selectedCustomerWorkspace['customer'] as Map<String, dynamic>
          : const <String, dynamic>{};

  List<Map<String, dynamic>> get customers => List<Map<String, dynamic>>.from(
    ((_customerListPage['items'] as List?) ??
            (workspace['customers'] as List?) ??
            const <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map)),
  );

  List<Map<String, dynamic>> get tasks => List<Map<String, dynamic>>.from(
    (workspace['tasks'] as List? ?? const <dynamic>[]).map(
      (item) => Map<String, dynamic>.from(item as Map),
    ),
  );

  List<Map<String, dynamic>> get notifications =>
      List<Map<String, dynamic>>.from(
        (workspace['notifications'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

  List<Map<String, dynamic>> get recentActivity =>
      List<Map<String, dynamic>>.from(
        (workspace['recentActivity'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

  List<Map<String, dynamic>> get upcomingAppointments =>
      List<Map<String, dynamic>>.from(
        (workspace['upcomingAppointments'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

  List<Map<String, dynamic>> get customerTasks =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['tasks'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

  List<Map<String, dynamic>> get customerActivities =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['activities'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerAppointments =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['appointments'] as List? ??
                const <dynamic>[])
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
        (selectedCustomerWorkspace['familyDetails'] as List? ??
                const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerAddresses =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['addresses'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  Map<String, dynamic> get customerPreferredProvider =>
      Map<String, dynamic>.from(
        selectedCustomerWorkspace['preferredProvider'] ?? const {},
      );

  List<Map<String, dynamic>> get customerPurchases =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['purchases'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerPrescriptions =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['prescriptions'] as List? ??
                const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerPharmacyRequests =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['pharmacyRequests'] as List? ??
                const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerStatusHistory =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['statusHistory'] as List? ??
                const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerMedicalRecords =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['medicalRecords'] as List? ??
                const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  List<Map<String, dynamic>> get customerTimeline =>
      List<Map<String, dynamic>>.from(
        (selectedCustomerWorkspace['timeline'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );

  Map<String, dynamic> get customerMembership => Map<String, dynamic>.from(
    selectedCustomerWorkspace['membership'] ?? const {},
  );

  Map<String, dynamic> get customerWallet => Map<String, dynamic>.from(
    selectedCustomerWorkspace['wallet'] ?? const {},
  );

  Map<String, dynamic> get customerReferralSummary => Map<String, dynamic>.from(
    selectedCustomerWorkspace['referralSummary'] ?? const {},
  );

  Map<String, dynamic> get customerPrinting => Map<String, dynamic>.from(
    selectedCustomerWorkspace['printing'] ?? const {},
  );

  List<Map<String, dynamic>> get availableReports =>
      List<Map<String, dynamic>>.from(
        (reportRegistry['reports'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
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
      final values = await Future.wait<dynamic>([
        _repository.getWorkspace(),
        _repository.getCustomers(),
        _ensureReferenceData(),
      ]);
      _workspace = values[0] as Map<String, dynamic>;
      _customerListPage = values[1] as Map<String, dynamic>;
      _selectedCustomerId ??= customers.isNotEmpty
          ? customers.first['id']?.toString()
          : null;
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

  Future<void> loadCustomerPage({
    String? query,
    String? status,
    String? membershipStatus,
    int page = 1,
    int pageSize = 25,
  }) async {
    _customerLoading = true;
    _error = null;
    notifyListeners();
    try {
      _customerListPage = await _repository.getCustomers(
        query: query,
        status: status,
        membershipStatus: membershipStatus,
        page: page,
        pageSize: pageSize,
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _customerLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureReferenceData({bool force = false}) async {
    if (_providers.isNotEmpty &&
        _businesses.isNotEmpty &&
        _membershipTypes.isNotEmpty &&
        _reportRegistry.isNotEmpty &&
        !force) {
      return;
    }

    _referenceDataLoading = true;
    _providerLookupError = null;
    notifyListeners();
    try {
      final providers = await _repository.getProviders();
      final businesses = await _repository.getBusinesses();
      final membershipTypes = await _repository.getMembershipTypes();
      final reports = await _repository.getReportRegistry();
      _providers = providers;
      _businesses = businesses;
      _membershipTypes = membershipTypes;
      _reportRegistry = reports;
      _providerLookupError = null;
    } catch (error) {
      _providerLookupError = _resolveReferenceDataError(error);
    } finally {
      _referenceDataLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadReferenceData({bool force = true}) async {
    await _ensureReferenceData(force: force);
  }

  Future<void> selectCustomer(String customerId) async {
    if (_customerLoading && _selectedCustomerId == customerId) {
      return _selectedCustomerRequest!;
    }
    if (_selectedCustomerId == customerId &&
        _selectedCustomerWorkspace.isNotEmpty) {
      return;
    }
    _selectedCustomerId = customerId;
    _customerLoading = true;
    _error = null;
    notifyListeners();
    final request = _repository.getCustomerWorkspace(customerId).then((value) {
      _selectedCustomerWorkspace = value;
    });
    _selectedCustomerRequest = request;
    try {
      await request;
    } catch (error) {
      _error = error.toString();
    } finally {
      if (identical(_selectedCustomerRequest, request)) {
        _selectedCustomerRequest = null;
      }
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

  Future<Map<String, dynamic>?> findExistingCustomerByMobile(String mobile) =>
      _repository.findExistingCustomerByMobile(mobile);

  Future<void> convertExistingCustomerToMembership({
    required String customerId,
    String? membershipTypeCode,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.convertExistingCustomerToMembership(
        customerId,
        membershipTypeCode: membershipTypeCode,
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

  Future<void> saveAlternativeCustomerContact({
    required String customerId,
    required Map<String, dynamic> payload,
  }) async {
    await _repository.saveAlternativeCustomerContact(customerId, payload);
    await selectCustomer(customerId);
  }

  Future<Map<String, dynamic>> getCustomerCardProfile(String customerId) =>
      _repository.getCustomerCardProfile(customerId);

  Future<void> requestCustomerPhysicalCard(String customerId) async {
    await _repository.requestCustomerPhysicalCard(customerId);
    await selectCustomer(customerId);
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
      final settings = await _repository.getCurrentPreferences();
      _workspace = <String, dynamic>{
        ..._workspace,
        'authProfile': profile,
        'agentSettings': settings,
      };
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _profileSaving = false;
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
      final profile = await _repository.getCurrentProfile();
      final preferences = await _repository.getCurrentPreferences();
      final sessions = await _repository.getSessions();
      final loginHistory = await _repository.getLoginHistory();
      _workspace = <String, dynamic>{
        ..._workspace,
        'authProfile': profile,
        'agentSettings': preferences,
      };
      _sessions = sessions;
      _loginHistory = loginHistory;
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

  Future<void> saveCurrentPreferences(Map<String, dynamic> payload) async {
    _profileSaving = true;
    _error = null;
    notifyListeners();
    try {
      final preferences = await _repository.updateCurrentPreferences(payload);
      final profile = await _repository.getCurrentProfile();
      _workspace = <String, dynamic>{
        ..._workspace,
        'authProfile': profile,
        'agentSettings': preferences,
      };
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _profileSaving = false;
      notifyListeners();
    }
  }

  Future<void> revokeOtherOwnedSessions() async {
    _settingsLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.revokeOtherSessions();
      await loadSettingsData();
    } catch (error) {
      _error = error.toString();
      _settingsLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> generateCustomerPrint(String templateId) async {
    final rawPayload = customerPrinting['payloads'] is Map
        ? Map<String, dynamic>.from(customerPrinting['payloads'] as Map)
        : const <String, dynamic>{};
    final templatePayload = rawPayload[templateId] is Map
        ? Map<String, dynamic>.from(rawPayload[templateId] as Map)
        : const <String, dynamic>{};
    if (templatePayload.isEmpty) {
      throw StateError('No shared print payload is available for $templateId.');
    }
    return _repository.generatePlatformPrint(templateId, templatePayload);
  }

  Future<Map<String, dynamic>> runAgentReport(
    String reportId, {
    String format = 'PDF',
    String? dateFrom,
    String? dateTo,
    String? status,
    String? search,
  }) {
    return _repository.runPlatformReport(
      reportId: reportId,
      format: format,
      dateFrom: dateFrom,
      dateTo: dateTo,
      status: status,
      search: search,
    );
  }

  Future<String> getCustomerDocumentDownloadUrl(String documentId) {
    return _repository.getDocumentDownloadUrl(documentId);
  }

  String _resolveReferenceDataError(Object error) {
    final message = error.toString().trim();
    final lowered = message.toLowerCase();
    if (lowered.contains('403') || lowered.contains('forbidden')) {
      return 'Your current SHIELD role can open the visit workflow, but provider-directory access was denied. Retry after permissions are updated or use an admin-approved account.';
    }
    if (lowered.contains('network')) {
      return 'The provider directory could not be reached because the network connection is unavailable. Retry when the connection is stable.';
    }
    return message.isEmpty
        ? 'The provider directory could not be loaded right now.'
        : message;
  }
}
