import 'package:flutter/foundation.dart';

import '../../../../../shared/models/appointment.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/document.dart';
import '../../../../../shared/models/notification.dart';
import '../../../../../shared/models/wallet.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/services/internal_auth_session.dart';
import '../../../../../shared/services/platform_realtime_channel.dart';
import '../../data/provider_portal_repository.dart';

class ProviderPortalController extends ChangeNotifier {
  ProviderPortalController(this._repository) {
    InternalAuthSession.instance.addListener(_handleAuthSessionChanged);
  }

  final ProviderPortalRepository _repository;

  void _trace(String message) {
    if (kDebugMode) {
      debugPrint('[ProviderPortalController] $message');
    }
  }

  String _tokenPreview(String? token) {
    final normalized = token?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'missing';
    }
    if (normalized.length <= 12) {
      return normalized;
    }
    return '${normalized.substring(0, 6)}...${normalized.substring(normalized.length - 4)}';
  }

  bool _loading = false;
  bool _workspaceLoaded = false;
  bool _customerLoading = false;
  bool _settingsLoading = false;
  bool _consultationLoading = false;
  bool _consultationSaving = false;
  bool _providerProfileSaving = false;
  String? _error;
  String? _realtimeError;
  String? _selectedCustomerId;
  String? _activeVisitAppointmentId;
  Map<String, dynamic>? _workspace;
  Map<String, dynamic>? _platformWorkspace;
  Map<String, dynamic>? _authProfile;
  Map<String, dynamic>? _providerProfile;
  Map<String, dynamic>? _consultationWorkspace;
  Map<String, dynamic>? _selectedPatientWorkspace;
  Customer? _selectedCustomer;
  Map<String, dynamic>? _selectedWallet;
  Map<String, dynamic>? _selectedMembership;
  List<Document> _selectedDocuments = const <Document>[];
  List<Appointment> _selectedAppointments = const <Appointment>[];
  List<NotificationModel> _selectedNotifications = const <NotificationModel>[];
  List<Map<String, dynamic>> _selectedPurchases =
      const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _selectedTimelineEntries =
      const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _sessions = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _loginHistory = const <Map<String, dynamic>>[];
  bool _realtimeConnected = false;
  bool _realtimeSubscribed = false;
  String? _lastPlatformEventType;
  PlatformRealtimeSubscription? _realtimeSubscription;

  bool get isLoading => _loading;
  bool get isWorkspaceLoaded => _workspaceLoaded;
  bool get isCustomerLoading => _customerLoading;
  bool get isSettingsLoading => _settingsLoading;
  bool get isConsultationLoading => _consultationLoading;
  bool get isConsultationSaving => _consultationSaving;
  bool get isProviderProfileSaving => _providerProfileSaving;
  String? get error => _error;
  String? get realtimeError => _realtimeError;
  String? get activeVisitAppointmentId => _activeVisitAppointmentId;
  Map<String, dynamic> get workspace => _workspace ?? const <String, dynamic>{};
  Map<String, dynamic> get platformWorkspace =>
      _platformWorkspace ?? const <String, dynamic>{};
  Map<String, dynamic> get authProfile =>
      _authProfile ?? const <String, dynamic>{};
  Map<String, dynamic> get providerProfile =>
      _providerProfile ?? const <String, dynamic>{};
  Map<String, dynamic> get consultationWorkspace =>
      _consultationWorkspace ?? const <String, dynamic>{};
  Map<String, dynamic> get selectedPatientWorkspace =>
      _selectedPatientWorkspace ?? const <String, dynamic>{};
  String? get selectedCustomerId => _selectedCustomerId;
  Customer? get selectedCustomer => _selectedCustomer;
  Map<String, dynamic>? get selectedWallet => _selectedWallet;
  Map<String, dynamic>? get selectedMembership => _selectedMembership;
  List<Document> get selectedDocuments => _selectedDocuments;
  List<Appointment> get selectedAppointments => _selectedAppointments;
  List<NotificationModel> get selectedNotifications => _selectedNotifications;
  List<Map<String, dynamic>> get selectedPurchases => _selectedPurchases;
  List<Map<String, dynamic>> get sessions => _sessions;
  List<Map<String, dynamic>> get loginHistory => _loginHistory;
  bool get isRealtimeConnected => _realtimeConnected;
  String? get lastPlatformEventType => _lastPlatformEventType;
  Map<String, dynamic> get printRegistry =>
      Map<String, dynamic>.from(platformWorkspace['printing'] ?? const {});
  Map<String, dynamic> get reportRegistry =>
      Map<String, dynamic>.from(platformWorkspace['reporting'] ?? const {});
  Map<String, dynamic> get realtimeRegistry =>
      Map<String, dynamic>.from(platformWorkspace['realtime'] ?? const {});
  List<Map<String, dynamic>> get availablePrintTemplates =>
      List<Map<String, dynamic>>.from(
        (printRegistry['templates'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
  List<Map<String, dynamic>> get availableReports =>
      List<Map<String, dynamic>>.from(
        ((reportRegistry['reports'] as List?) ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

  List<Map<String, dynamic>> get providers =>
      List<Map<String, dynamic>>.from(workspace['providers'] ?? const []);
  List<Map<String, dynamic>> get customers =>
      List<Map<String, dynamic>>.from(workspace['customers'] ?? const []);
  Map<String, dynamic> get summary =>
      Map<String, dynamic>.from(workspace['summary'] ?? const {});
  Map<String, dynamic> get workspaceMeta =>
      Map<String, dynamic>.from(workspace['workspaceMeta'] ?? const {});
  Map<String, dynamic> get providerContextMetadata =>
      Map<String, dynamic>.from(workspaceMeta['providerContext'] ?? const {});
  Map<String, dynamic> get workspaceMessages =>
      Map<String, dynamic>.from(workspaceMeta['messages'] ?? const {});
  Map<String, dynamic> get workspaceLabels =>
      Map<String, dynamic>.from(workspaceMeta['labels'] ?? const {});
  Map<String, dynamic> get workspaceFilters =>
      Map<String, dynamic>.from(workspaceMeta['filters'] ?? const {});
  List<Map<String, dynamic>> get dashboardWidgetMetadata =>
      List<Map<String, dynamic>>.from(
        (workspaceMeta['dashboardWidgets'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
  List<Map<String, dynamic>> get providerWorklists =>
      List<Map<String, dynamic>>.from(
        (workspaceMeta['worklists'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
  List<Map<String, dynamic>> get workspaceQuickActions =>
      List<Map<String, dynamic>>.from(
        (workspaceMeta['quickActions'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
  List<Map<String, dynamic>> get queueFilters =>
      List<Map<String, dynamic>>.from(
        (workspaceFilters['queue'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
  Map<String, dynamic> get queues =>
      Map<String, dynamic>.from(workspace['queues'] ?? const {});
  List<Map<String, dynamic>> get appointmentQueue =>
      List<Map<String, dynamic>>.from(queues['appointments'] ?? const []);
  List<Map<String, dynamic>> get billingQueue =>
      List<Map<String, dynamic>>.from(queues['billing'] ?? const []);
  List<Map<String, dynamic>> get workflowQueue => [
    ...appointmentQueue.map((item) => <String, dynamic>{...item}),
    ...billingQueue.map((item) => <String, dynamic>{...item}),
  ];

  List<Map<String, dynamic>> get queueStagesMetadata {
    final stages = List<Map<String, dynamic>>.from(
      (workspaceMeta['queueStages'] as List? ?? const <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    stages.sort(
      (left, right) =>
          (left['order'] as num? ?? 0).compareTo(right['order'] as num? ?? 0),
    );
    return stages;
  }

  List<Map<String, dynamic>> get dashboardHighlights {
    final cards = List<Map<String, dynamic>>.from(
      (workspaceMeta['dashboardHighlights'] as List? ?? const <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    cards.sort(
      (left, right) =>
          (left['order'] as num? ?? 0).compareTo(right['order'] as num? ?? 0),
    );
    return cards;
  }

  Map<String, dynamic> get patientWorkspaceMetadata =>
      Map<String, dynamic>.from(workspaceMeta['patientWorkspace'] ?? const {});

  List<Map<String, dynamic>> get patientWorkspaceTabs {
    final tabs = List<Map<String, dynamic>>.from(
      (patientWorkspaceMetadata['tabs'] as List? ?? const <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    tabs.sort(
      (left, right) =>
          (left['order'] as num? ?? 0).compareTo(right['order'] as num? ?? 0),
    );
    return tabs;
  }

  String get patientWorkspaceEmptyStateMessage =>
      patientWorkspaceMetadata['emptyStateMessage']?.toString() ??
      'Select a patient to open the full care view.';

  String get patientWorkspaceTitle =>
      patientWorkspaceMetadata['title']?.toString() ?? 'Patient Record';

  String get patientWorkspaceDescription =>
      patientWorkspaceMetadata['description']?.toString() ??
      'Open one patient and keep visits, records, and payments together in one place.';

  List<Map<String, dynamic>> get patientWorkspaceHeaderFields {
    final fields = List<Map<String, dynamic>>.from(
      (patientWorkspaceMetadata['headerFields'] as List? ?? const <dynamic>[])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    fields.sort(
      (left, right) =>
          (left['order'] as num? ?? 0).compareTo(right['order'] as num? ?? 0),
    );
    return fields;
  }

  List<Map<String, dynamic>> get patientWorkspaceQuickActions {
    final actions = List<Map<String, dynamic>>.from(
      (patientWorkspaceMetadata['quickActions'] as List? ?? const <dynamic>[])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    return actions;
  }

  Map<String, dynamic> get searchConfig =>
      Map<String, dynamic>.from(workspaceMeta['searchConfig'] ?? const {});

  String get patientSearchTitle =>
      searchConfig['title']?.toString() ?? 'Search patient';

  String get patientSearchSubtitle =>
      searchConfig['subtitle']?.toString() ??
      'Open one patient and keep visits, records, membership, and payments together in a single patient record.';

  String get patientSearchPlaceholder =>
      searchConfig['placeholder']?.toString() ??
      'Search by name, patient ID, phone, membership, or SHIELD card';

  List<String> get patientSearchSupportedQueries =>
      List<String>.from(searchConfig['supportedQueries'] ?? const <String>[]);

  String get patientSearchEmptyStateMessage =>
      searchConfig['emptyStateMessage']?.toString() ??
      'No patients match this search yet.';

  Map<String, dynamic> get timelineConfig =>
      Map<String, dynamic>.from(workspaceMeta['timelineConfig'] ?? const {});

  String get timelineTitle => timelineConfig['title']?.toString() ?? 'Timeline';

  String get timelineSubtitle =>
      timelineConfig['subtitle']?.toString() ??
      'Use the patient timeline to follow the care story in one place.';

  String get providerDisplayName {
    final display =
        authProfile['display'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final displayName = display['fullName']?.toString().trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }
    final principal =
        authProfile['principal'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final principalDisplayName =
        principal['displayName']?.toString().trim() ?? '';
    if (principalDisplayName.isNotEmpty) {
      return principalDisplayName;
    }
    final profile =
        authProfile['profile'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final firstName = profile['firstName']?.toString().trim() ?? '';
    final lastName = profile['lastName']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'SHIELD Provider' : fullName;
  }

  String get providerRoleLabel {
    final display =
        authProfile['display'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final designation = display['designation']?.toString().trim() ?? '';
    if (designation.isNotEmpty) {
      return designation;
    }
    final principal =
        authProfile['principal'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return principal['roleLabel']?.toString() ??
        principal['roleCode']?.toString().replaceAll('_', ' ') ??
        'Provider';
  }

  String get providerBranchLabel {
    final display =
        authProfile['display'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final branch =
        display['branch'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final branchName = branch['name']?.toString().trim() ?? '';
    if (branchName.isNotEmpty) {
      return branchName;
    }
    final principal =
        authProfile['principal'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return principal['branchLabel']?.toString() ?? 'Branch not assigned';
  }

  bool hasPermission(String code) {
    final principal =
        authProfile['principal'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final permissions = List<String>.from(
      principal['permissions'] ?? const <String>[],
    );
    return permissions.contains(code);
  }

  Map<String, List<Map<String, dynamic>>> get queueByStage {
    final buckets = <String, List<Map<String, dynamic>>>{
      for (final stage in queueStagesMetadata)
        stage['code']?.toString() ?? '': <Map<String, dynamic>>[],
    }..remove('');

    for (final item in workflowQueue) {
      final stage = _resolveWorkflowStage(item);
      buckets.putIfAbsent(stage, () => <Map<String, dynamic>>[]).add(item);
    }

    return buckets;
  }

  Map<String, int> get queueStageCounts => {
    for (final entry in queueByStage.entries) entry.key: entry.value.length,
  };

  List<Map<String, dynamic>> get urgentQueueItems {
    final ranked = workflowQueue.toList()
      ..sort((a, b) {
        final left = _priorityRank(a);
        final right = _priorityRank(b);
        if (left != right) {
          return left.compareTo(right);
        }
        return _resolveWorkflowStage(a).compareTo(_resolveWorkflowStage(b));
      });
    return ranked.take(4).toList();
  }

  List<Appointment> get selectedUpcomingAppointments {
    final now = DateTime.now();
    final upcoming =
        selectedAppointments
            .where((appointment) => appointment.appointmentDate.isAfter(now))
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    return upcoming;
  }

  List<Map<String, dynamic>> get workspaceAppointmentsToday {
    final items = appointmentQueue.toList()
      ..sort((left, right) {
        final leftMeta = left['meta']?.toString() ?? '';
        final rightMeta = right['meta']?.toString() ?? '';
        return leftMeta.compareTo(rightMeta);
      });
    return items;
  }

  List<Appointment> get selectedCompletedAppointments {
    final completed =
        selectedAppointments
            .where(
              (appointment) =>
                  appointment.status == AppointmentStatus.completed,
            )
            .toList()
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    return completed;
  }

  List<Document> get selectedRecentDocuments {
    final recent = selectedDocuments.toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return recent;
  }

  List<Document> get selectedPrescriptionDocuments => selectedRecentDocuments
      .where((document) => document.typeLabel == 'Prescription')
      .toList();

  List<Document> get selectedLabReportDocuments => selectedRecentDocuments
      .where((document) => document.typeLabel == 'Lab report')
      .toList();

  List<Document> get selectedInvoiceDocuments => selectedRecentDocuments
      .where((document) => document.typeLabel == 'Invoice')
      .toList();

  List<Document> get selectedOtherDocuments => selectedRecentDocuments
      .where(
        (document) =>
            document.typeLabel != 'Prescription' &&
            document.typeLabel != 'Lab report' &&
            document.typeLabel != 'Invoice',
      )
      .toList();

  List<WalletTransaction> get selectedWalletTransactions =>
      ((selectedWallet?['recentTransactions'] as List? ?? const <dynamic>[]))
          .map(
            (item) => WalletTransaction.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Map<String, dynamic> get selectedBenefitSummary =>
      Map<String, dynamic>.from(selectedWallet?['benefitSummary'] ?? const {});

  Map<String, dynamic> get selectedWalletStatistics =>
      Map<String, dynamic>.from(selectedWallet?['statistics'] ?? const {});

  Appointment? get activeVisitAppointment {
    final activeId = _activeVisitAppointmentId;
    if (activeId == null || activeId.isEmpty) {
      return null;
    }
    for (final appointment in selectedAppointments) {
      if (appointment.id == activeId) {
        return appointment;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get consultationActions =>
      List<Map<String, dynamic>>.from(
        (consultationWorkspace['actions'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

  List<Map<String, dynamic>> get consultationFormSections {
    final sections = List<Map<String, dynamic>>.from(
      (consultationWorkspace['formSections'] as List? ?? const <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    sections.sort(
      (left, right) =>
          (left['order'] as num? ?? 0).compareTo(right['order'] as num? ?? 0),
    );
    return sections;
  }

  Map<String, dynamic> get consultationForm =>
      Map<String, dynamic>.from(consultationWorkspace['form'] ?? const {});

  Map<String, dynamic> get activeVisitStatusSummary =>
      Map<String, dynamic>.from(consultationWorkspace['statusSummary'] ?? const {});

  Map<String, dynamic> get activeVisitSummary =>
      Map<String, dynamic>.from(consultationWorkspace['visit'] ?? const {});

  Map<String, dynamic> get activeVisitBilling =>
      Map<String, dynamic>.from(consultationWorkspace['billing'] ?? const {});
  Map<String, dynamic> get activeVisitPrescription =>
      Map<String, dynamic>.from(
        consultationWorkspace['prescription'] ?? const {},
      );

  List<Map<String, dynamic>> get activeVisitTimeline =>
      List<Map<String, dynamic>>.from(
        (consultationWorkspace['timeline'] as List? ?? const <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

  String get activeVisitStatusLabel =>
      consultationWorkspace['statusLabel']?.toString() ?? 'Waiting';

  List<Map<String, dynamic>> get selectedTimeline =>
      _selectedTimelineEntries.toList();

  Future<void> ensureLoaded() async {
    if (_loading || _workspaceLoaded) {
      _trace(
        'ensureLoaded skipped loading=$_loading workspaceLoaded=$_workspaceLoaded',
      );
      return;
    }
    _trace(
      'ensureLoaded started authInitialized=${InternalAuthSession.instance.isInitialized} authAuthenticated=${InternalAuthSession.instance.isAuthenticated}',
    );
    await refreshWorkspace();
    if (_workspaceLoaded) {
      await attachRealtimeStream();
    }
  }

  void _handleAuthSessionChanged() {
    final authSession = InternalAuthSession.instance;
    _trace(
      'auth session changed initialized=${authSession.isInitialized} authenticated=${authSession.isAuthenticated} workspaceLoaded=$_workspaceLoaded realtimeSubscribed=$_realtimeSubscribed',
    );
    if (!_workspaceLoaded ||
        _realtimeSubscribed ||
        !authSession.isInitialized ||
        !authSession.isAuthenticated) {
      return;
    }
    Future<void>.microtask(attachRealtimeStream);
  }

  Future<void> retryStartup() async {
    _trace('startup retry requested');
    _resetRealtimeSubscription();
    await refreshWorkspace();
    if (_workspaceLoaded) {
      await attachRealtimeStream();
    }
  }

  Future<void> refreshWorkspace() async {
    _loading = true;
    _error = null;
    _trace('workspace load started');
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getOperationalWorkspace(),
        _repository.getPlatformWorkspace(),
        _repository.getAuthenticatedProfile(),
        _repository.getProviderProfile(),
      ]);
      final operationalWorkspace = Map<String, dynamic>.from(results[0]);
      final platformWorkspace = Map<String, dynamic>.from(results[1]);
      final mergedWorkspace = Map<String, dynamic>.from(operationalWorkspace);
      mergedWorkspace['workspaceMeta'] =
          platformWorkspace['workspaceMeta'] ??
          operationalWorkspace['workspaceMeta'] ??
          const <String, dynamic>{};
      _workspace = mergedWorkspace;
      _platformWorkspace = platformWorkspace;
      _authProfile = results[2];
      _providerProfile = results[3];
      _workspaceLoaded = true;
      _trace('workspace loaded successfully');
      _selectedCustomerId ??= customers.isNotEmpty
          ? customers.first['id']?.toString()
          : null;
    } catch (error) {
      _trace('workspace load failed error=$error');
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }

    if (_selectedCustomerId != null) {
      await selectCustomer(_selectedCustomerId!);
    }
  }

  Future<void> attachRealtimeStream() async {
    if (_realtimeSubscribed) {
      _trace(
        'realtime attach skipped subscribed=$_realtimeSubscribed connected=$_realtimeConnected',
      );
      return;
    }

    final authSession = InternalAuthSession.instance;
    if (!authSession.isInitialized || !authSession.isAuthenticated) {
      _trace(
        'realtime attach skipped authInitialized=${authSession.isInitialized} authAuthenticated=${authSession.isAuthenticated}',
      );
      return;
    }

    final accessToken = ApiService.currentAccessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _trace('realtime attach skipped token missing');
      return;
    }

    final workspaceKey =
        realtimeRegistry['workspace']?.toString().trim().toLowerCase() ??
        'provider';
    _trace(
      'realtime connect requested workspace=$workspaceKey token=${_tokenPreview(accessToken)}',
    );
    _realtimeError = null;
    _realtimeSubscription = connectPlatformRealtimeStream(
      baseUrl: ApiService.currentBaseUrl,
      workspace: workspaceKey,
      accessToken: accessToken,
      onEvent: (event) {
        _realtimeConnected = true;
        _realtimeError = null;
        _lastPlatformEventType = event['type']?.toString();
        _trace('realtime event received type=$_lastPlatformEventType');
        notifyListeners();
        if (_lastPlatformEventType == 'STREAM_CONNECTED') {
          return;
        }
        Future<void>.microtask(() async {
          await refreshWorkspace();
          final selectedId = _selectedCustomerId;
          final eventCustomerId = event['customerId']?.toString().trim();
          if (selectedId != null &&
              (eventCustomerId == null ||
                  eventCustomerId.isEmpty ||
                  eventCustomerId == selectedId)) {
            await selectCustomer(selectedId);
          }
        });
      },
      onError: (error) {
        _realtimeError = error.toString();
        _trace('realtime failed error=$error');
        _resetRealtimeSubscription();
        notifyListeners();
      },
    );
    _realtimeSubscribed = true;
    _trace('realtime subscription created');
    notifyListeners();
  }

  void _resetRealtimeSubscription() {
    _realtimeSubscription?.dispose();
    _realtimeSubscription = null;
    _realtimeSubscribed = false;
    _realtimeConnected = false;
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
      final workspace = await _repository.getPatientWorkspace(customerId);
      _applySelectedPatientWorkspace(workspace);
    } catch (error) {
      _error = error.toString();
    } finally {
      _customerLoading = false;
      notifyListeners();
    }

    if (_consultationWorkspace == null && _activeVisitAppointmentId != null) {
      await loadConsultationWorkspace(_activeVisitAppointmentId!);
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
      final profile = await _repository.getProviderProfile();
      final sessions = await _repository.getSessions();
      final loginHistory = await _repository.getLoginHistory();
      _providerProfile = profile;
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

  Future<void> reloadProviderProfile() async {
    try {
      _providerProfile = await _repository.getProviderProfile();
      _authProfile = await _repository.getAuthenticatedProfile();
    } catch (error) {
      _error = error.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveProviderProfile(Map<String, dynamic> payload) async {
    _providerProfileSaving = true;
    _error = null;
    notifyListeners();

    try {
      _providerProfile = await _repository.updateProviderProfile(payload);
      _authProfile = await _repository.getAuthenticatedProfile();
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _providerProfileSaving = false;
      notifyListeners();
    }
  }

  Future<void> saveProviderPreferences(Map<String, dynamic> payload) async {
    _providerProfileSaving = true;
    _error = null;
    notifyListeners();

    try {
      _providerProfile = await _repository.updateProviderPreferences(payload);
      _authProfile = await _repository.getAuthenticatedProfile();
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _providerProfileSaving = false;
      notifyListeners();
    }
  }

  Future<void> uploadProviderProfilePhoto({
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
    required int fileSize,
  }) async {
    _providerProfileSaving = true;
    _error = null;
    notifyListeners();

    try {
      _providerProfile = await _repository.uploadProviderProfilePhoto(
        fileName: fileName,
        fileBytes: fileBytes,
        mimeType: mimeType,
        fileSize: fileSize,
      );
      _authProfile = await _repository.getAuthenticatedProfile();
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _providerProfileSaving = false;
      notifyListeners();
    }
  }

  Future<void> uploadProviderSignature({
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
    required int fileSize,
  }) async {
    _providerProfileSaving = true;
    _error = null;
    notifyListeners();

    try {
      _providerProfile = await _repository.uploadProviderSignature(
        fileName: fileName,
        fileBytes: fileBytes,
        mimeType: mimeType,
        fileSize: fileSize,
      );
      _authProfile = await _repository.getAuthenticatedProfile();
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _providerProfileSaving = false;
      notifyListeners();
    }
  }

  Future<void> loadConsultationWorkspace(String appointmentId) async {
    _activeVisitAppointmentId = appointmentId;
    _consultationLoading = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.getConsultationWorkspace(
        appointmentId,
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationLoading = false;
      notifyListeners();
    }
  }

  Future<void> openAppointmentWorkflow(
    Appointment appointment, {
    bool loadConsultation = false,
  }) async {
    await selectCustomer(appointment.customerId);
    _activeVisitAppointmentId = appointment.id;
    if (loadConsultation) {
      await loadConsultationWorkspace(appointment.id);
    } else {
      notifyListeners();
    }
  }

  Future<void> confirmAppointment(String appointmentId) async {
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.confirmAppointment(appointmentId);
      await _reloadAppointmentState(updated);
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.cancelAppointment(appointmentId);
      await _reloadAppointmentState(updated);
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> startConsultationForActiveVisit() async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.startConsultation(
        appointmentId,
      );
      await _reloadSelectedCustomerData();
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> saveActiveConsultation(Map<String, String> formData) async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.saveConsultation(
        appointmentId,
        _consultationPayload(formData),
      );
      await _reloadSelectedCustomerData();
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> completeActiveConsultation(Map<String, String> formData) async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.completeConsultation(
        appointmentId,
        _consultationPayload(formData),
      );
      await _reloadSelectedCustomerData(preferredAppointmentId: appointmentId);
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> saveActiveVisitBilling(Map<String, dynamic> payload) async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.saveVisitBilling(
        appointmentId,
        payload,
      );
      await _reloadSelectedCustomerData(preferredAppointmentId: appointmentId);
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> generateActiveVisitInvoice(Map<String, dynamic> payload) async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.generateVisitInvoice(
        appointmentId,
        payload,
      );
      await _reloadSelectedCustomerData(preferredAppointmentId: appointmentId);
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> recordActiveVisitPayment(Map<String, dynamic> payload) async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.recordVisitPayment(
        appointmentId,
        payload,
      );
      await _reloadSelectedCustomerData(preferredAppointmentId: appointmentId);
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> searchMedicineCatalog(String query) {
    return _repository.searchProducts(query);
  }

  Future<void> saveActiveVisitPrescriptionDraft(
    Map<String, dynamic> payload,
  ) async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.savePrescriptionDraft(
        appointmentId,
        payload,
      );
      await _reloadSelectedCustomerData(preferredAppointmentId: appointmentId);
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> finalizeActiveVisitPrescription(
    Map<String, dynamic> payload, {
    bool sendToPharmacy = false,
  }) async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.finalizePrescription(
        appointmentId,
        {
          ...payload,
          'sendToPharmacy': sendToPharmacy,
        },
      );
      await _reloadSelectedCustomerData(preferredAppointmentId: appointmentId);
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> duplicatePreviousPrescription() async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.duplicatePreviousPrescription(
        appointmentId,
      );
      await _reloadSelectedCustomerData(preferredAppointmentId: appointmentId);
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> copyHistoricalPrescriptionToOpenVisit() async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.copyPrescriptionToOpenVisit(
        appointmentId,
      );
      final targetAppointmentId =
          _consultationWorkspace?['appointmentId']?.toString() ?? appointmentId;
      _activeVisitAppointmentId = targetAppointmentId;
      await _reloadSelectedCustomerData(
        preferredAppointmentId: targetAppointmentId,
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<void> voidActiveVisitInvoice({String? reason}) async {
    final appointmentId = _activeVisitAppointmentId;
    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }
    _consultationSaving = true;
    _error = null;
    notifyListeners();

    try {
      _consultationWorkspace = await _repository.voidVisitInvoice(
        appointmentId,
        reason: reason,
      );
      await _reloadSelectedCustomerData(preferredAppointmentId: appointmentId);
    } catch (error) {
      _error = error.toString();
    } finally {
      _consultationSaving = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> generatePatientPrint(String templateId) async {
    final payloads =
        selectedPatientWorkspace['printing'] is Map
            ? Map<String, dynamic>.from(selectedPatientWorkspace['printing'])
            : const <String, dynamic>{};
    final rawPayload =
        payloads['payloads'] is Map
            ? Map<String, dynamic>.from(payloads['payloads'] as Map)
            : const <String, dynamic>{};
    final templatePayload =
        rawPayload[templateId] is Map
            ? Map<String, dynamic>.from(rawPayload[templateId] as Map)
            : const <String, dynamic>{};
    if (templatePayload.isEmpty) {
      throw StateError('No shared print payload is available for $templateId.');
    }
    return _repository.generatePlatformPrint(templateId, templatePayload);
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

  Future<Map<String, dynamic>> runProviderReport(
    String reportId, {
    String format = 'PDF',
  }) {
    final display =
        authProfile['display'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final branch = display['branch'] as Map<String, dynamic>? ?? const {};
    return _repository.runPlatformReport(
      reportId: reportId,
      workspace: 'provider',
      format: format,
      businessId: branch['id']?.toString(),
    );
  }

  Future<String> getPatientDocumentDownloadUrl(String documentId) {
    return _repository.getDocumentDownloadUrl(documentId);
  }

  String queueStageTitle(String stageCode) {
    for (final stage in queueStagesMetadata) {
      if (stage['code']?.toString() == stageCode) {
        return stage['title']?.toString() ?? stageCode.replaceAll('_', ' ');
      }
    }
    return stageCode.replaceAll('_', ' ');
  }

  String queueStageEmptyState(String stageCode) {
    for (final stage in queueStagesMetadata) {
      if (stage['code']?.toString() == stageCode) {
        return stage['emptyStateMessage']?.toString() ??
            'Everything is up to date.';
      }
    }
    return 'Everything is up to date.';
  }

  int queueCountForStages(List<String> stageCodes) {
    var total = 0;
    for (final stageCode in stageCodes) {
      total += queueStageCounts[stageCode] ?? 0;
    }
    return total;
  }

  String patientTabTitle(String tabCode) {
    for (final tab in patientWorkspaceTabs) {
      if (tab['code']?.toString() == tabCode) {
        return tab['title']?.toString() ?? tabCode;
      }
    }
    return tabCode;
  }

  String patientTabEmptyState(String tabCode) {
    for (final tab in patientWorkspaceTabs) {
      if (tab['code']?.toString() == tabCode) {
        return tab['emptyStateMessage']?.toString() ??
            'No information is available yet.';
      }
    }
    return 'No information is available yet.';
  }

  String patientHeaderFieldValue(String fieldCode) {
    switch (fieldCode) {
      case 'membership':
        return (((selectedMembership?['membership'] as Map<String, dynamic>?) ??
                    const <String, dynamic>{})['membershipNumber'])
                ?.toString() ??
            'Not issued';
      case 'shield-card':
        return selectedCustomer?.shieldCardNumber ?? 'Pending issuance';
      case 'wallet':
        final cashWallet =
            selectedWallet?['cashWallet'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        return formatCurrency(cashWallet['available']);
      case 'blood-group':
        return selectedCustomer?.bloodGroup ?? 'Not recorded';
      case 'location':
        final location = [selectedCustomer?.city, selectedCustomer?.district]
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .join(', ');
        return location.isEmpty ? 'Location not recorded' : location;
      case 'upcoming-appointment':
        final next = selectedUpcomingAppointments.isNotEmpty
            ? selectedUpcomingAppointments.first
            : null;
        return next == null ? 'No visit scheduled' : next.typeLabel;
      default:
        return '';
    }
  }

  String patientQuickActionTargetTab(Map<String, dynamic> action) =>
      action['targetTab']?.toString() ?? 'overview';

  String consultationFieldValue(String fieldCode) =>
      consultationForm[fieldCode]?.toString() ?? '';

  int get selectedOutstandingInvoiceCount => selectedPurchases
      .where(
        (purchase) =>
            (double.tryParse(
                  '${purchase['payableAmount'] ?? purchase['payable_amount'] ?? 0}',
                ) ??
                0) >
            0,
      )
      .length;

  double get selectedTotalPurchaseValue => selectedPurchases.fold<double>(
    0,
    (sum, purchase) =>
        sum +
        (double.tryParse(
              '${purchase['payableAmount'] ?? purchase['payable_amount'] ?? 0}',
            ) ??
            0),
  );

  String formatCurrency(Object? value) {
    final amount = double.tryParse('${value ?? 0}') ?? 0;
    return 'Rs ${amount.toStringAsFixed(0)}';
  }

  String resolvePatientTab(String? tabCode) {
    final tabs = patientWorkspaceTabs;
    if (tabs.isEmpty) {
      return 'overview';
    }
    final defaultTab = tabs.first['code']?.toString() ?? 'overview';
    final requested = tabCode?.trim();
    if (requested == null || requested.isEmpty) {
      return defaultTab;
    }
    final isSupported = tabs.any((tab) => tab['code']?.toString() == requested);
    return isSupported ? requested : defaultTab;
  }

  List<Map<String, dynamic>> queueItemsForFilter(String? filterCode) {
    final normalized = filterCode?.trim();
    if (normalized == null || normalized.isEmpty || normalized == 'all') {
      return workflowQueue;
    }
    Map<String, dynamic>? filter;
    for (final item in queueFilters) {
      if (item['code']?.toString() == normalized) {
        filter = item;
        break;
      }
    }
    if (filter == null) {
      return workflowQueue;
    }
    final stageCodes = List<String>.from(filter['stageCodes'] ?? const <String>[]);
    if (stageCodes.isEmpty) {
      return workflowQueue;
    }
    return workflowQueue
        .where((item) => stageCodes.contains(_resolveWorkflowStage(item)))
        .map((item) => <String, dynamic>{...item})
        .toList();
  }

  int dashboardHighlightValue(Map<String, dynamic> meta) {
    final metricKind = meta['metricKind']?.toString() ?? '';
    if (metricKind == 'urgent') {
      return urgentQueueItems.length;
    }
    final stageCodes = List<String>.from(
      meta['stageCodes'] ?? const <String>[],
    );
    return queueCountForStages(stageCodes);
  }

  String? queueCustomerId(Map<String, dynamic> item) {
    final customerId = item['customerId']?.toString().trim() ?? '';
    return customerId.isEmpty ? null : customerId;
  }

  String queueTargetSection(
    Map<String, dynamic> item, {
    required bool primary,
  }) {
    final key = primary ? 'primaryTargetSection' : 'secondaryTargetSection';
    final section = item[key]?.toString().trim() ?? '';
    return section.isEmpty ? 'customers' : section;
  }

  String queueTargetTab(Map<String, dynamic> item, {required bool primary}) {
    final key = primary ? 'primaryTargetTab' : 'secondaryTargetTab';
    final tab = item[key]?.toString().trim() ?? '';
    return tab.isEmpty ? 'overview' : tab;
  }

  Future<bool> prepareQueuePatient(Map<String, dynamic> item) async {
    final customerId = queueCustomerId(item);
    if (customerId == null) {
      return false;
    }
    await selectCustomer(customerId);
    return true;
  }

  String _resolveWorkflowStage(Map<String, dynamic> item) {
    final backendStage =
        item['stageCode']?.toString().trim().toUpperCase() ?? '';
    if (backendStage.isNotEmpty) {
      return backendStage;
    }
    final normalized = (item['status']?.toString() ?? '').trim().toUpperCase();
    if (normalized.contains('COMPLETE') || normalized.contains('APPROVED')) {
      return 'COMPLETED';
    }
    if (normalized.contains('READY') || normalized.contains('VALIDATED')) {
      return 'READY_TO_COMPLETE';
    }
    if (normalized.contains('WAIT')) {
      return 'WAITING';
    }
    if (normalized.contains('PROGRESS') ||
        normalized.contains('CHECKED') ||
        normalized.contains('PROCESS')) {
      return 'CONSULTATION';
    }
    if (normalized.contains('ASSIGN') ||
        normalized.contains('SCHEDULED') ||
        normalized.contains('CONFIRM')) {
      return 'ACCEPTED';
    }
    return queueStagesMetadata.isNotEmpty
        ? queueStagesMetadata.first['code']?.toString() ?? 'WAITING'
        : 'WAITING';
  }

  int _priorityRank(Map<String, dynamic> item) {
    final title = item['title']?.toString().toUpperCase() ?? '';
    final subtitle = item['subtitle']?.toString().toUpperCase() ?? '';
    final meta = item['meta']?.toString().toUpperCase() ?? '';
    final combined = '$title $subtitle $meta';
    if (combined.contains('URGENT') || combined.contains('EMERGENCY')) {
      return 0;
    }
    if (combined.contains('WAITING')) {
      return 1;
    }
    if (combined.contains('PENDING')) {
      return 2;
    }
    return 3;
  }

  String? _resolvePrimaryVisitAppointmentId() {
    final incomplete =
        selectedAppointments
            .where(
              (appointment) =>
                  appointment.status != AppointmentStatus.completed &&
                  appointment.status != AppointmentStatus.cancelled,
            )
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    if (incomplete.isNotEmpty) {
      return incomplete.first.id;
    }

    final completed = selectedAppointments.toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    return completed.isEmpty ? null : completed.first.id;
  }

  Map<String, dynamic> _consultationPayload(Map<String, String> formData) => {
    'chief_complaint': formData['chiefComplaint']?.trim() ?? '',
    'symptoms': formData['symptoms']?.trim() ?? '',
    'clinical_findings': formData['clinicalFindings']?.trim() ?? '',
    'diagnosis': formData['diagnosis']?.trim() ?? '',
    'advice': formData['advice']?.trim() ?? '',
    'procedures': formData['procedures']?.trim() ?? '',
    'lab_orders': formData['labOrders']?.trim() ?? '',
    'follow_up': formData['followUp']?.trim() ?? '',
    'provider_notes': formData['providerNotes']?.trim() ?? '',
  };

  Future<void> _reloadSelectedCustomerData({
    String? preferredAppointmentId,
  }) async {
    final customerId = _selectedCustomerId;
    if (customerId == null || customerId.isEmpty) {
      return;
    }

    final workspace = await _repository.getPatientWorkspace(customerId);
    _applySelectedPatientWorkspace(
      workspace,
      preferredAppointmentId: preferredAppointmentId,
    );

    if (_consultationWorkspace == null && _activeVisitAppointmentId != null) {
      _consultationWorkspace = await _repository.getConsultationWorkspace(
        _activeVisitAppointmentId!,
      );
    }
  }

  Future<void> _reloadAppointmentState(Appointment appointment) async {
    if (selectedCustomerId == appointment.customerId) {
      await _reloadSelectedCustomerData(preferredAppointmentId: appointment.id);
    } else {
      await selectCustomer(appointment.customerId);
      _activeVisitAppointmentId = appointment.id;
    }
    await refreshWorkspace();
  }

  void _applySelectedPatientWorkspace(
    Map<String, dynamic> workspace, {
    String? preferredAppointmentId,
  }) {
    _selectedPatientWorkspace = Map<String, dynamic>.from(workspace);
    _selectedCustomer = Customer.fromJson(
      Map<String, dynamic>.from(workspace['patient'] as Map? ?? const {}),
    );
    _selectedWallet = Map<String, dynamic>.from(
      workspace['wallet'] as Map? ?? const {},
    );
    _selectedMembership = Map<String, dynamic>.from(
      workspace['membership'] as Map? ?? const {},
    );
    _selectedDocuments =
        (workspace['documents'] is Map
                ? ((workspace['documents'] as Map)['items'] as List? ??
                      const <dynamic>[])
                : const <dynamic>[])
            .whereType<Map>()
            .map((item) => Document.fromJson(Map<String, dynamic>.from(item)))
            .toList();
    _selectedAppointments =
        (workspace['appointments'] is Map
                ? ((workspace['appointments'] as Map)['items'] as List? ??
                      const <dynamic>[])
                : const <dynamic>[])
            .whereType<Map>()
            .map(
              (item) => Appointment.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
    _selectedNotifications =
        (workspace['notifications'] is Map
                ? ((workspace['notifications'] as Map)['items'] as List? ??
                      const <dynamic>[])
                : const <dynamic>[])
            .whereType<Map>()
            .map(
              (item) =>
                  NotificationModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
    _selectedPurchases =
        (workspace['billing'] is Map
                ? ((workspace['billing'] as Map)['items'] as List? ??
                      const <dynamic>[])
                : const <dynamic>[])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    _selectedTimelineEntries = _parseBackendTimeline(
      workspace['timeline'] as List? ?? const <dynamic>[],
    );

    final activeVisit = Map<String, dynamic>.from(
      workspace['activeVisit'] as Map? ?? const {},
    );
    final activeVisitWorkspace = activeVisit['workspace'] as Map?;
    _consultationWorkspace = activeVisitWorkspace == null
        ? null
        : Map<String, dynamic>.from(activeVisitWorkspace);
    _activeVisitAppointmentId =
        preferredAppointmentId ??
        activeVisit['appointmentId']?.toString() ??
        _resolvePrimaryVisitAppointmentId();
  }

  List<Map<String, dynamic>> _parseBackendTimeline(List<dynamic> items) {
    final timeline = items.whereType<Map>().map((item) {
      final entry = Map<String, dynamic>.from(item);
      entry['timestamp'] =
          DateTime.tryParse(entry['timestamp']?.toString() ?? '') ??
          DateTime.now();
      return entry;
    }).toList();
    timeline.sort(
      (left, right) => (right['timestamp'] as DateTime).compareTo(
        left['timestamp'] as DateTime,
      ),
    );
    return timeline;
  }

  @override
  void dispose() {
    InternalAuthSession.instance.removeListener(_handleAuthSessionChanged);
    _resetRealtimeSubscription();
    super.dispose();
  }
}


