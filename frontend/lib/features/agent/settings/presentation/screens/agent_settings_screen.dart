import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/services/internal_auth_session.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_design_system.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentSettingsScreen extends ConsumerStatefulWidget {
  const AgentSettingsScreen({super.key, this.profileOnly = false});

  final bool profileOnly;

  @override
  ConsumerState<AgentSettingsScreen> createState() =>
      _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends ConsumerState<AgentSettingsScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _workingAreaController = TextEditingController();
  final _workingDistrictController = TextEditingController();
  final _travelRadiusController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _deviceLabelController = TextEditingController();
  final _workingStartController = TextEditingController();
  final _workingEndController = TextEditingController();
  final _branchNotesController = TextEditingController();

  String _theme = 'system';
  String _language = 'en';
  String _timezone = 'Asia/Calcutta';
  String _defaultDashboard = 'overview';
  String _availabilityMode = 'FIELD';
  String? _requestedBranchId;
  bool _availableForAssignments = true;
  bool _followUpReminders = true;
  bool _appointmentChanges = true;
  bool _referralUpdates = true;
  bool _membershipReminders = true;
  bool _showCustomerCodes = true;
  bool _showMembershipBadges = true;
  bool _allowPushNotifications = true;
  String? _settingsVersion;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _workingAreaController.dispose();
    _workingDistrictController.dispose();
    _travelRadiusController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _deviceLabelController.dispose();
    _workingStartController.dispose();
    _workingEndController.dispose();
    _branchNotesController.dispose();
    super.dispose();
  }

  void _hydrateProfile(Map<String, dynamic> profile) {
    final profileData = Map<String, dynamic>.from(
      profile['profile'] ?? const {},
    );
    _firstNameController.text = profileData['firstName']?.toString() ?? '';
    _lastNameController.text = profileData['lastName']?.toString() ?? '';
    _mobileController.text = profileData['mobile']?.toString() ?? '';
    _emailController.text = profileData['email']?.toString() ?? '';
  }

  void _hydrateSettings(Map<String, dynamic> settings) {
    if (settings.isEmpty) {
      return;
    }
    final version =
        settings['updatedAt']?.toString() ??
        settings['preferenceId']?.toString() ??
        'agent-settings';
    if (_settingsVersion == version) {
      return;
    }

    final preferences = Map<String, dynamic>.from(
      settings['preferences'] ?? const {},
    );
    final availability = Map<String, dynamic>.from(
      preferences['availability'] ?? const {},
    );
    final workingHours = Map<String, dynamic>.from(
      preferences['workingHours'] ?? const {},
    );
    final workingArea = Map<String, dynamic>.from(
      preferences['workingArea'] ?? const {},
    );
    final emergencyContact = Map<String, dynamic>.from(
      preferences['emergencyContact'] ?? const {},
    );
    final notifications = Map<String, dynamic>.from(
      preferences['notifications'] ?? const {},
    );
    final dashboardLayout = Map<String, dynamic>.from(
      preferences['dashboardLayout'] ?? const {},
    );
    final profilePreferences = Map<String, dynamic>.from(
      preferences['profilePreferences'] ?? const {},
    );
    final devicePreferences = Map<String, dynamic>.from(
      preferences['devicePreferences'] ?? const {},
    );
    final branchLifecycle = Map<String, dynamic>.from(
      settings['branchLifecycle'] ?? const {},
    );
    final requestedBranch = branchLifecycle['requestedBranch'] is Map
        ? Map<String, dynamic>.from(branchLifecycle['requestedBranch'] as Map)
        : const <String, dynamic>{};

    _theme = _sanitizeChoice(preferences['theme']?.toString(), const [
      'system',
      'light',
      'dark',
    ], 'system');
    _language = _sanitizeChoice(preferences['language']?.toString(), const [
      'en',
      'ml',
      'hi',
    ], 'en');
    _timezone = _sanitizeChoice(preferences['timezone']?.toString(), const [
      'Asia/Calcutta',
      'Asia/Dubai',
      'UTC',
    ], 'Asia/Calcutta');
    _defaultDashboard = _sanitizeChoice(
      dashboardLayout['defaultView']?.toString(),
      const ['overview', 'customers', 'followups'],
      'overview',
    );
    _availabilityMode = _sanitizeChoice(
      availability['mode']?.toString(),
      const ['FIELD', 'REMOTE', 'HYBRID'],
      'FIELD',
    );
    _availableForAssignments = availability['availableForAssignments'] != false;
    _followUpReminders = notifications['followUpReminders'] != false;
    _appointmentChanges = notifications['appointmentChanges'] != false;
    _referralUpdates = notifications['referralUpdates'] != false;
    _membershipReminders = notifications['membershipReminders'] != false;
    _showCustomerCodes = profilePreferences['showCustomerCodes'] != false;
    _showMembershipBadges = profilePreferences['showMembershipBadges'] != false;
    _allowPushNotifications =
        devicePreferences['allowPushNotifications'] != false;
    _requestedBranchId = requestedBranch['businessId']?.toString();
    _workingAreaController.text = workingArea['label']?.toString() ?? '';
    _workingDistrictController.text = workingArea['district']?.toString() ?? '';
    _travelRadiusController.text =
        workingArea['travelRadiusKm']?.toString() ?? '15';
    _emergencyNameController.text = emergencyContact['name']?.toString() ?? '';
    _emergencyPhoneController.text =
        emergencyContact['phone']?.toString() ?? '';
    _emergencyRelationController.text =
        emergencyContact['relation']?.toString() ?? '';
    _deviceLabelController.text =
        devicePreferences['preferredDeviceLabel']?.toString() ?? '';
    _workingStartController.text =
        workingHours['startTime']?.toString() ?? '09:00';
    _workingEndController.text = workingHours['endTime']?.toString() ?? '18:00';
    _branchNotesController.text = requestedBranch['notes']?.toString() ?? '';
    _settingsVersion = version;
  }

  Future<void> _saveProfile(dynamic controller) async {
    try {
      await controller.updateCurrentProfile({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
      });
      if (!mounted) {
        return;
      }
      _showMessage('Profile updated successfully.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(
        controller.error?.toString() ?? 'Unable to update the profile.',
      );
    }
  }

  Future<void> _saveSettings(dynamic controller) async {
    try {
      await controller.saveCurrentPreferences({
        'requestedBranchId': _requestedBranchId,
        'branchNotes': _branchNotesController.text.trim(),
        'preferences': {
          'theme': _theme,
          'language': _language,
          'timezone': _timezone,
          'availability': {
            'mode': _availabilityMode,
            'availableForAssignments': _availableForAssignments,
            'status': _availableForAssignments ? 'ACTIVE' : 'PAUSED',
          },
          'workingHours': {
            'startTime': _workingStartController.text.trim(),
            'endTime': _workingEndController.text.trim(),
            'workingDays': const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
          },
          'workingArea': {
            'label': _workingAreaController.text.trim(),
            'district': _workingDistrictController.text.trim(),
            'travelRadiusKm':
                int.tryParse(_travelRadiusController.text.trim()) ?? 15,
          },
          'emergencyContact': {
            'name': _emergencyNameController.text.trim(),
            'phone': _emergencyPhoneController.text.trim(),
            'relation': _emergencyRelationController.text.trim(),
          },
          'notifications': {
            'followUpReminders': _followUpReminders,
            'appointmentChanges': _appointmentChanges,
            'referralUpdates': _referralUpdates,
            'membershipReminders': _membershipReminders,
          },
          'dashboardLayout': {'defaultView': _defaultDashboard},
          'profilePreferences': {
            'showCustomerCodes': _showCustomerCodes,
            'showMembershipBadges': _showMembershipBadges,
          },
          'devicePreferences': {
            'preferredDeviceLabel': _deviceLabelController.text.trim(),
            'allowPushNotifications': _allowPushNotifications,
          },
        },
      });
      if (!mounted) {
        return;
      }
      _showMessage('Settings updated successfully.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(
        controller.error?.toString() ?? 'Unable to update the settings.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final authProfile = controller.authProfile;
    final settings = controller.agentSettings.isNotEmpty
        ? controller.agentSettings
        : Map<String, dynamic>.from(authProfile['settings'] ?? const {});
    final display = Map<String, dynamic>.from(
      authProfile['display'] ?? const {},
    );
    final branchLifecycle = Map<String, dynamic>.from(
      settings['branchLifecycle'] ?? const {},
    );
    final assignments = List<Map<String, dynamic>>.from(
      (branchLifecycle['assignments'] as List? ?? const <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    final branches = List<Map<String, dynamic>>.from(
      ((settings['lookups'] as Map?)?['branches'] as List? ?? const <dynamic>[])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    final safeRequestedBranchId =
        branches.any((branch) => branch['id']?.toString() == _requestedBranchId)
        ? _requestedBranchId
        : null;

    _hydrateProfile(authProfile);
    _hydrateSettings(settings);

    if (!controller.isSettingsLoading &&
        controller.agentSettings.isEmpty &&
        !widget.profileOnly) {
      Future.microtask(
        () => ref.read(agentPortalControllerProvider).loadSettingsData(),
      );
    }

    if (widget.profileOnly) {
      return _buildAccountView(
        context,
        controller,
        display: display,
        branchLifecycle: branchLifecycle,
      );
    }

    return _buildSettingsView(
      context,
      controller,
      display: display,
      branchLifecycle: branchLifecycle,
      assignments: assignments,
      branches: branches,
      safeRequestedBranchId: safeRequestedBranchId,
    );
  }

  Widget _buildAccountView(
    BuildContext context,
    dynamic controller, {
    required Map<String, dynamic> display,
    required Map<String, dynamic> branchLifecycle,
  }) {
    final bodyHeight = (MediaQuery.sizeOf(context).height - 260).clamp(
      280.0,
      900.0,
    );
    final sections = <Widget>[
      AgentInsetSurface(
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                _displayName()
                    .split(RegExp(r'\s+'))
                    .take(2)
                    .map((part) => part.substring(0, 1).toUpperCase())
                    .join(),
              ),
            ),
            AgentUi.gapW(AgentSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    display['fullName']?.toString().ifBlank(_displayName()) ??
                        _displayName(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  AgentUi.gapH(AgentSpacing.xxs),
                  Text(
                    display['employeeCode']?.toString().ifBlank('-') ?? '-',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  AgentUi.gapH(AgentSpacing.xs),
                  Wrap(
                    spacing: AgentSpacing.xs,
                    runSpacing: AgentSpacing.xs,
                    children: [
                      AgentStatusBadge(
                        label: _availableForAssignments ? 'Active' : 'Paused',
                        color: _availableForAssignments
                            ? AgentColors.success
                            : AgentColors.warning,
                        icon: Icons.verified_user_outlined,
                      ),
                      AgentStatusBadge(
                        label: _workingModeLabel(_availabilityMode),
                        color: AgentColors.accentTeal,
                        icon: Icons.location_on_outlined,
                      ),
                      AgentStatusBadge(
                        label:
                            display['designation']?.toString().ifBlank(
                              'Field Agent',
                            ) ??
                            'Field Agent',
                        color: AgentColors.accentIndigo,
                        icon: Icons.badge_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      AgentUi.gapH(AgentSpacing.sm),
      AgentPanelCard(
        title: 'Personal Information',
        subtitle: 'Editable identity details.',
        child: Wrap(
          spacing: AgentUi.space12,
          runSpacing: AgentUi.space12,
          children: [
            AgentFormFieldWidth(
              child: TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
            ),
            AgentFormFieldWidth(
              child: TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
            ),
            AgentFormFieldWidth(
              child: TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ),
            AgentFormFieldWidth(
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ),
          ],
        ),
      ),
      AgentUi.gapH(AgentUi.space12),
      AgentPanelCard(
        title: 'Employee Information',
        subtitle: 'Read-only assignment details.',
        child: Wrap(
          spacing: AgentUi.space12,
          runSpacing: AgentUi.space12,
          children: [
            SizedBox(
              width: 240,
              child: AgentKeyValueItem(
                label: 'Full Name',
                value:
                    display['fullName']?.toString().ifBlank(_displayName()) ??
                    _displayName(),
                icon: Icons.person_outline,
              ),
            ),
            SizedBox(
              width: 240,
              child: AgentKeyValueItem(
                label: 'Employee Code',
                value: display['employeeCode']?.toString().ifBlank('-') ?? '-',
                icon: Icons.badge_outlined,
              ),
            ),
            SizedBox(
              width: 240,
              child: AgentKeyValueItem(
                label: 'Role',
                value:
                    display['designation']?.toString().ifBlank('Field Agent') ??
                    'Field Agent',
                icon: Icons.account_circle_outlined,
              ),
            ),
            SizedBox(
              width: 240,
              child: AgentKeyValueItem(
                label: 'Assigned Branch',
                value: _resolveBranchName(
                  branchLifecycle,
                ).ifBlank('Pending assignment'),
                icon: Icons.business_outlined,
              ),
            ),
            SizedBox(
              width: 240,
              child: AgentKeyValueItem(
                label: 'Working Area',
                value: _workingAreaController.text.ifBlank('Not set'),
                icon: Icons.map_outlined,
              ),
            ),
            SizedBox(
              width: 240,
              child: AgentKeyValueItem(
                label: 'Availability',
                value: _workingModeLabel(_availabilityMode),
                icon: Icons.location_on_outlined,
              ),
            ),
            SizedBox(
              width: 240,
              child: AgentKeyValueItem(
                label: 'Account Status',
                value: _availableForAssignments ? 'Active' : 'Paused',
                icon: Icons.verified_user_outlined,
              ),
            ),
            SizedBox(
              width: 240,
              child: AgentKeyValueItem(
                label: 'Last Login',
                value:
                    display['lastLoginAt']?.toString().ifBlank(
                      'Not recorded',
                    ) ??
                    'Not recorded',
                icon: Icons.history_outlined,
              ),
            ),
          ],
        ),
      ),
      AgentUi.gapH(AgentUi.space12),
      Align(
        alignment: Alignment.centerRight,
        child: AgentPrimaryButton(
          onPressed: controller.isProfileSaving
              ? null
              : () => _saveProfile(controller),
          icon: const Icon(Icons.save_outlined),
          label: controller.isProfileSaving ? 'Saving...' : 'Save Profile',
          isLoading: controller.isProfileSaving,
        ),
      ),
    ];

    return AgentWorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AgentSectionHeader(
            title: 'Profile',
            description: 'Manage identity and assignment details here.',
          ),
          AgentUi.gapH(AgentUi.space16),
          SizedBox(
            height: bodyHeight,
            child: ListView(children: sections),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView(
    BuildContext context,
    dynamic controller, {
    required Map<String, dynamic> display,
    required Map<String, dynamic> branchLifecycle,
    required List<Map<String, dynamic>> assignments,
    required List<Map<String, dynamic>> branches,
    required String? safeRequestedBranchId,
  }) {
    final bodyHeight = (MediaQuery.sizeOf(context).height - 300).clamp(
      300.0,
      900.0,
    );
    return DefaultTabController(
      length: 3,
      child: AgentWorkspaceSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AgentSectionHeader(
              title: 'Settings',
              description:
                  'Manage app behavior, workspace defaults, and security here. Identity details stay in Profile.',
            ),
            AgentUi.gapH(AgentUi.space16),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Preferences'),
                Tab(text: 'Workspace'),
                Tab(text: 'Security'),
              ],
            ),
            AgentUi.gapH(AgentUi.space16),
            SizedBox(
              height: bodyHeight,
              child: TabBarView(
                children: [
                  ListView(
                    children: [
                      AgentPanelCard(
                        title: 'Appearance and Workflow',
                        subtitle: 'Defaults for how the portal opens.',
                        child: Wrap(
                          spacing: AgentUi.space12,
                          runSpacing: AgentUi.space12,
                          children: [
                            AgentFormFieldWidth(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _theme,
                                decoration: const InputDecoration(
                                  labelText: 'Theme',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'system',
                                    child: Text('Use device setting'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'light',
                                    child: Text('Light'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'dark',
                                    child: Text('Dark'),
                                  ),
                                ],
                                onChanged: controller.isProfileSaving
                                    ? null
                                    : (value) => setState(
                                        () => _theme = value ?? 'system',
                                      ),
                              ),
                            ),
                            AgentFormFieldWidth(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _language,
                                decoration: const InputDecoration(
                                  labelText: 'Language',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Text('English'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ml',
                                    child: Text('Malayalam'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'hi',
                                    child: Text('Hindi'),
                                  ),
                                ],
                                onChanged: controller.isProfileSaving
                                    ? null
                                    : (value) => setState(
                                        () => _language = value ?? 'en',
                                      ),
                              ),
                            ),
                            AgentFormFieldWidth(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _timezone,
                                decoration: const InputDecoration(
                                  labelText: 'Timezone',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Asia/Calcutta',
                                    child: Text('India Standard Time'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Asia/Dubai',
                                    child: Text('Gulf Standard Time'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UTC',
                                    child: Text('UTC'),
                                  ),
                                ],
                                onChanged: controller.isProfileSaving
                                    ? null
                                    : (value) => setState(
                                        () => _timezone =
                                            value ?? 'Asia/Calcutta',
                                      ),
                              ),
                            ),
                            AgentFormFieldWidth(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _defaultDashboard,
                                decoration: const InputDecoration(
                                  labelText: 'Default Dashboard',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'overview',
                                    child: Text('Overview'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'customers',
                                    child: Text('Customers'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'followups',
                                    child: Text('Follow-ups'),
                                  ),
                                ],
                                onChanged: controller.isProfileSaving
                                    ? null
                                    : (value) => setState(
                                        () => _defaultDashboard =
                                            value ?? 'overview',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AgentUi.gapH(AgentUi.space12),
                      AgentPanelCard(
                        title: 'Notifications and Display',
                        subtitle:
                            'Reminders, push delivery, and display defaults.',
                        child: Column(
                          children: [
                            _SettingsToggleTile(
                              label: 'Allow push notifications',
                              icon: Icons.notifications_outlined,
                              value: _allowPushNotifications,
                              enabled: !controller.isProfileSaving,
                              onChanged: (value) => setState(
                                () => _allowPushNotifications = value,
                              ),
                            ),
                            _SettingsToggleTile(
                              label: 'Follow-up reminders',
                              icon: Icons.assignment_turned_in_outlined,
                              value: _followUpReminders,
                              enabled: !controller.isProfileSaving,
                              onChanged: (value) =>
                                  setState(() => _followUpReminders = value),
                            ),
                            _SettingsToggleTile(
                              label: 'Appointment change alerts',
                              icon: Icons.event_available_outlined,
                              value: _appointmentChanges,
                              enabled: !controller.isProfileSaving,
                              onChanged: (value) =>
                                  setState(() => _appointmentChanges = value),
                            ),
                            _SettingsToggleTile(
                              label: 'Network update alerts',
                              icon: Icons.account_tree_outlined,
                              value: _referralUpdates,
                              enabled: !controller.isProfileSaving,
                              onChanged: (value) =>
                                  setState(() => _referralUpdates = value),
                            ),
                            _SettingsToggleTile(
                              label: 'Membership reminder alerts',
                              icon: Icons.card_membership_outlined,
                              value: _membershipReminders,
                              enabled: !controller.isProfileSaving,
                              onChanged: (value) =>
                                  setState(() => _membershipReminders = value),
                            ),
                            _SettingsToggleTile(
                              label: 'Show customer codes by default',
                              icon: Icons.badge_outlined,
                              value: _showCustomerCodes,
                              enabled: !controller.isProfileSaving,
                              onChanged: (value) =>
                                  setState(() => _showCustomerCodes = value),
                            ),
                            _SettingsToggleTile(
                              label: 'Show membership badges',
                              icon: Icons.sell_outlined,
                              value: _showMembershipBadges,
                              enabled: !controller.isProfileSaving,
                              onChanged: (value) =>
                                  setState(() => _showMembershipBadges = value),
                            ),
                            AgentUi.gapH(AgentSpacing.xs),
                            AgentFormFieldWidth(
                              child: TextField(
                                controller: _deviceLabelController,
                                decoration: const InputDecoration(
                                  labelText: 'Current Device Label',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AgentUi.gapH(AgentUi.space12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AgentPrimaryButton(
                          onPressed: controller.isProfileSaving
                              ? null
                              : () => _saveSettings(controller),
                          icon: const Icon(Icons.save_outlined),
                          label: controller.isProfileSaving
                              ? 'Saving...'
                              : 'Save Preferences',
                          isLoading: controller.isProfileSaving,
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    children: [
                      AgentPanelCard(
                        title: 'Availability and Working Hours',
                        subtitle:
                            'Schedule and routing behavior for assignments.',
                        child: Column(
                          children: [
                            _SettingsToggleTile(
                              label: 'Available for new assignments',
                              icon: Icons.fact_check_outlined,
                              value: _availableForAssignments,
                              enabled: !controller.isProfileSaving,
                              onChanged: (value) => setState(
                                () => _availableForAssignments = value,
                              ),
                            ),
                            AgentUi.gapH(AgentUi.space12),
                            Wrap(
                              spacing: AgentUi.space12,
                              runSpacing: AgentUi.space12,
                              children: [
                                AgentFormFieldWidth(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _availabilityMode,
                                    decoration: const InputDecoration(
                                      labelText: 'Working Mode',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'FIELD',
                                        child: Text('Field'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'REMOTE',
                                        child: Text('Office / Remote'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'HYBRID',
                                        child: Text('Hybrid'),
                                      ),
                                    ],
                                    onChanged: controller.isProfileSaving
                                        ? null
                                        : (value) => setState(
                                            () => _availabilityMode =
                                                value ?? 'FIELD',
                                          ),
                                  ),
                                ),
                                AgentFormFieldWidth(
                                  child: TextField(
                                    controller: _workingStartController,
                                    decoration: const InputDecoration(
                                      labelText: 'Working Hours Start',
                                    ),
                                  ),
                                ),
                                AgentFormFieldWidth(
                                  child: TextField(
                                    controller: _workingEndController,
                                    decoration: const InputDecoration(
                                      labelText: 'Working Hours End',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AgentUi.gapH(AgentUi.space12),
                      AgentPanelCard(
                        title: 'Field Coverage and Emergency Contact',
                        subtitle: 'Coverage details and emergency contact.',
                        child: Wrap(
                          spacing: AgentUi.space12,
                          runSpacing: AgentUi.space12,
                          children: [
                            AgentFormFieldWidth(
                              child: TextField(
                                controller: _workingAreaController,
                                decoration: const InputDecoration(
                                  labelText: 'Working Area Label',
                                ),
                              ),
                            ),
                            AgentFormFieldWidth(
                              child: TextField(
                                controller: _workingDistrictController,
                                decoration: const InputDecoration(
                                  labelText: 'District',
                                ),
                              ),
                            ),
                            AgentFormFieldWidth(
                              child: TextField(
                                controller: _travelRadiusController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Travel Radius (km)',
                                ),
                              ),
                            ),
                            AgentFormFieldWidth(
                              child: TextField(
                                controller: _emergencyNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Emergency Contact Name',
                                ),
                              ),
                            ),
                            AgentFormFieldWidth(
                              child: TextField(
                                controller: _emergencyPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Emergency Contact Phone',
                                ),
                              ),
                            ),
                            AgentFormFieldWidth(
                              child: TextField(
                                controller: _emergencyRelationController,
                                decoration: const InputDecoration(
                                  labelText: 'Relationship',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AgentUi.gapH(AgentUi.space12),
                      AgentPanelCard(
                        title: 'Request Branch Transfer',
                        subtitle:
                            'Submit a branch request and review its history.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current branch: ${_resolveBranchName(branchLifecycle).ifBlank('Not assigned')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            AgentUi.gapH(AgentSpacing.xs),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: safeRequestedBranchId,
                              decoration: const InputDecoration(
                                labelText: 'Requested Branch',
                              ),
                              items: branches
                                  .map(
                                    (branch) => DropdownMenuItem<String>(
                                      value: branch['id']?.toString() ?? '',
                                      child: Text(
                                        '${branch['name'] ?? 'Branch'} (${branch['code'] ?? '-'})',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: controller.isProfileSaving
                                  ? null
                                  : (value) => setState(
                                      () => _requestedBranchId = value,
                                    ),
                            ),
                            AgentUi.gapH(AgentUi.space12),
                            TextField(
                              controller: _branchNotesController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Reason',
                              ),
                            ),
                            AgentUi.gapH(AgentUi.space16),
                            if (assignments.isEmpty)
                              const Text(
                                'No branch lifecycle history is available yet.',
                              )
                            else
                              ...assignments.map<Widget>(
                                (assignment) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.business_outlined),
                                  title: Text(
                                    assignment['business'] is Map
                                        ? (assignment['business']
                                                      as Map)['name']
                                                  ?.toString() ??
                                              'Branch'
                                        : 'Branch',
                                  ),
                                  subtitle: Text(
                                    'Status: ${assignment['status'] ?? 'PENDING'}${assignment['notes']?.toString().isNotEmpty == true ? ' • ${assignment['notes']}' : ''}',
                                  ),
                                  trailing: assignment['isPrimary'] == true
                                      ? AgentStatusBadge(
                                          label: 'Primary',
                                          color: AgentUi.statusColor(
                                            context,
                                            'ACTIVE',
                                          ),
                                          icon: Icons.check_circle_outline,
                                        )
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                      AgentUi.gapH(AgentUi.space12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AgentPrimaryButton(
                          onPressed: controller.isProfileSaving
                              ? null
                              : () => _saveSettings(controller),
                          icon: const Icon(Icons.save_outlined),
                          label: controller.isProfileSaving
                              ? 'Saving...'
                              : 'Save Workspace Settings',
                          isLoading: controller.isProfileSaving,
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    children: [
                      AgentPanelCard(
                        title: 'Session Management',
                        subtitle:
                            'Security actions for the current SHIELD account.',
                        child: Wrap(
                          spacing: AgentUi.space8,
                          runSpacing: AgentUi.space8,
                          children: [
                            AgentPrimaryButton(
                              onPressed: InternalAuthSession.instance.signOut,
                              icon: const Icon(Icons.logout_outlined),
                              label: 'Sign Out',
                            ),
                            AgentSecondaryButton(
                              onPressed: controller.isSettingsLoading
                                  ? null
                                  : () => ref
                                        .read(agentPortalControllerProvider)
                                        .revokeOtherOwnedSessions(),
                              icon: const Icon(Icons.phonelink_erase_outlined),
                              label: 'Sign Out Other Devices',
                            ),
                          ],
                        ),
                      ),
                      AgentUi.gapH(AgentUi.space12),
                      AgentPanelCard(
                        title: 'Active Sessions',
                        subtitle:
                            'Devices currently signed in with this account.',
                        child: controller.sessions.isEmpty
                            ? const AgentEmptyState(
                                icon: Icons.devices_outlined,
                                title: 'No active sessions',
                                message:
                                    'Session information will appear here once SHIELD records device activity for this account.',
                              )
                            : Column(
                                children: controller.sessions
                                    .map<Widget>(
                                      (session) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.devices_outlined,
                                        ),
                                        title: Text(
                                          _describeSessionDevice(session),
                                        ),
                                        subtitle: Text(
                                          _describeSessionMeta(session),
                                        ),
                                        trailing: session['isCurrent'] == true
                                            ? AgentStatusBadge(
                                                label: 'Current',
                                                color: AgentUi.statusColor(
                                                  context,
                                                  'ACTIVE',
                                                ),
                                                icon:
                                                    Icons.check_circle_outline,
                                              )
                                            : AgentGhostButton(
                                                onPressed: () => ref
                                                    .read(
                                                      agentPortalControllerProvider,
                                                    )
                                                    .revokeOwnedSession(
                                                      session['sessionId']
                                                              ?.toString() ??
                                                          '',
                                                    ),
                                                label: 'Revoke',
                                              ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      AgentUi.gapH(AgentUi.space12),
                      AgentPanelCard(
                        title: 'Login History',
                        subtitle: 'Recent access activity.',
                        child: controller.loginHistory.isEmpty
                            ? const AgentEmptyState(
                                icon: Icons.history_outlined,
                                title: 'No login history',
                                message:
                                    'Recent login activity will appear here after the first recorded sessions.',
                              )
                            : Column(
                                children: controller.loginHistory
                                    .take(10)
                                    .map<Widget>(
                                      (row) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.history_outlined,
                                        ),
                                        title: Text(_describeLoginTitle(row)),
                                        subtitle: Text(_describeLoginMeta(row)),
                                        trailing: Text(
                                          _formatLoginAt(row['createdAt']),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveBranchName(Map<String, dynamic> branchLifecycle) {
    final currentBranch = branchLifecycle['activeBranch'] is Map
        ? (branchLifecycle['activeBranch'] as Map)['name']?.toString()
        : null;
    return currentBranch ?? '';
  }

  String _humanize(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) {
      return 'Unknown';
    }
    return text
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _displayName() {
    final name =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();
    return name.ifBlank('SHIELD Agent');
  }

  String _sanitizeChoice(String? value, List<String> allowed, String fallback) {
    return allowed.contains(value) ? value! : fallback;
  }

  String _workingModeLabel(String value) {
    switch (value.toUpperCase()) {
      case 'HYBRID':
        return 'Hybrid';
      case 'REMOTE':
        return 'Office / Remote';
      default:
        return 'Field';
    }
  }

  String _describeSessionDevice(Map<String, dynamic> session) {
    final device = session['device'] is Map
        ? Map<String, dynamic>.from(session['device'] as Map)
        : const <String, dynamic>{};
    final browser = device['browser']?.toString();
    final os = device['os']?.toString();
    final fallback = device['deviceName']?.toString();
    final joined = [
      browser,
      os,
    ].where((item) => (item ?? '').trim().isNotEmpty).join(' on ');
    return joined.ifBlank((fallback ?? '').ifBlank('Session'));
  }

  String _describeSessionMeta(Map<String, dynamic> session) {
    final method = _humanize(session['loginMethod']);
    final device = session['device'] is Map
        ? Map<String, dynamic>.from(session['device'] as Map)
        : const <String, dynamic>{};
    final location = [
      device['city']?.toString(),
      device['region']?.toString(),
    ].where((item) => (item ?? '').trim().isNotEmpty).join(', ');
    return [method, location.ifBlank(session['lastActiveAt']?.toString() ?? '')]
        .where((item) => (item).trim().isNotEmpty)
        .join(' • ')
        .ifBlank('Internal login');
  }

  String _describeLoginTitle(Map<String, dynamic> row) {
    final status = _humanize(row['status']);
    final method = _humanize(row['loginMethod']);
    return '$status • $method';
  }

  String _describeLoginMeta(Map<String, dynamic> row) {
    final device = row['device'] is Map
        ? Map<String, dynamic>.from(row['device'] as Map)
        : const <String, dynamic>{};
    final browser = device['browser']?.toString();
    final os = device['os']?.toString();
    final location = [
      device['city']?.toString(),
      device['region']?.toString(),
    ].where((item) => (item ?? '').trim().isNotEmpty).join(', ');
    return [browser, os, location]
        .where((item) => (item ?? '').trim().isNotEmpty)
        .join(' • ')
        .ifBlank('Device details unavailable');
  }

  String _formatLoginAt(dynamic value) {
    final raw = (value ?? '').toString().trim();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.ifBlank('-');
    }
    return '${DateFormat('dd MMM yyyy').format(parsed.toLocal())}\n${DateFormat('h:mm a').format(parsed.toLocal())}';
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      value: value,
      onChanged: enabled ? onChanged : null,
      title: Text(label),
    );
  }
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
