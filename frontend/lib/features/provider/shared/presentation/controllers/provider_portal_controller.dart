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
  List<Map<String, dynamic>> get workflowQueue => [
    ...appointmentQueue.map(
      (item) => <String, dynamic>{...item},
    ),
    ...billingQueue.map(
      (item) => <String, dynamic>{...item},
    ),
  ];

  String get providerDisplayName {
    final display = authProfile['display'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final displayName = display['fullName']?.toString().trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }
    final principal = authProfile['principal'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final principalDisplayName = principal['displayName']?.toString().trim() ?? '';
    if (principalDisplayName.isNotEmpty) {
      return principalDisplayName;
    }
    final profile = authProfile['profile'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final firstName = profile['firstName']?.toString().trim() ?? '';
    final lastName = profile['lastName']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'SHIELD Provider' : fullName;
  }

  String get providerRoleLabel {
    final display = authProfile['display'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final designation = display['designation']?.toString().trim() ?? '';
    if (designation.isNotEmpty) {
      return designation;
    }
    final principal = authProfile['principal'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return principal['roleLabel']?.toString() ??
        principal['roleCode']?.toString().replaceAll('_', ' ') ??
        'Provider';
  }

  String get providerBranchLabel {
    final display = authProfile['display'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final branch = display['branch'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final branchName = branch['name']?.toString().trim() ?? '';
    if (branchName.isNotEmpty) {
      return branchName;
    }
    final principal = authProfile['principal'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return principal['branchLabel']?.toString() ?? 'Branch not assigned';
  }

  Map<String, List<Map<String, dynamic>>> get queueByStage {
    final buckets = <String, List<Map<String, dynamic>>>{
      'NEW': <Map<String, dynamic>>[],
      'ASSIGNED': <Map<String, dynamic>>[],
      'IN_PROGRESS': <Map<String, dynamic>>[],
      'WAITING': <Map<String, dynamic>>[],
      'READY': <Map<String, dynamic>>[],
      'COMPLETED': <Map<String, dynamic>>[],
    };

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
    final upcoming = selectedAppointments
        .where((appointment) => appointment.appointmentDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    return upcoming;
  }

  List<Appointment> get selectedCompletedAppointments {
    final completed = selectedAppointments
        .where((appointment) => appointment.status == AppointmentStatus.completed)
        .toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    return completed;
  }

  List<Document> get selectedRecentDocuments {
    final recent = selectedDocuments.toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return recent;
  }

  List<Map<String, dynamic>> get selectedTimeline {
    final items = <Map<String, dynamic>>[];
    for (final appointment in selectedAppointments) {
      items.add({
        'kind': 'APPOINTMENT',
        'title': appointment.typeLabel,
        'subtitle': appointment.statusLabel,
        'timestamp': appointment.appointmentDate,
      });
    }
    for (final document in selectedDocuments) {
      items.add({
        'kind': 'DOCUMENT',
        'title': document.fileName,
        'subtitle': '${document.typeLabel} • ${document.statusLabel}',
        'timestamp': document.uploadedAt,
      });
    }
    items.sort(
      (a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime),
    );
    return items;
  }

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

  String _resolveWorkflowStage(Map<String, dynamic> item) {
    final backendStage = item['stageCode']?.toString().trim().toUpperCase() ?? '';
    if (backendStage.isNotEmpty) {
      switch (backendStage) {
        case 'ACCEPTED':
          return 'ASSIGNED';
        case 'CONSULTATION':
          return 'IN_PROGRESS';
        case 'WAITING_PAYMENT':
        case 'WAITING':
          return 'WAITING';
        case 'READY_TO_COMPLETE':
          return 'READY';
        case 'COMPLETED':
          return 'COMPLETED';
      }
    }
    final normalized = (item['status']?.toString() ?? '').trim().toUpperCase();
    if (normalized.contains('COMPLETE') || normalized.contains('APPROVED')) {
      return 'COMPLETED';
    }
    if (normalized.contains('READY') || normalized.contains('VALIDATED')) {
      return 'READY';
    }
    if (normalized.contains('WAIT')) {
      return 'WAITING';
    }
    if (normalized.contains('PROGRESS') ||
        normalized.contains('CHECKED') ||
        normalized.contains('PROCESS')) {
      return 'IN_PROGRESS';
    }
    if (normalized.contains('ASSIGN') ||
        normalized.contains('SCHEDULED') ||
        normalized.contains('CONFIRM')) {
      return 'ASSIGNED';
    }
    return 'NEW';
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
}
