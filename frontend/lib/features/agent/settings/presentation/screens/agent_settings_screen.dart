import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/services/internal_auth_session.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentSettingsScreen extends ConsumerStatefulWidget {
  const AgentSettingsScreen({super.key, this.profileOnly = false});

  final bool profileOnly;

  @override
  ConsumerState<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
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
    final profileData = Map<String, dynamic>.from(profile['profile'] ?? const {});
    _firstNameController.text = profileData['firstName']?.toString() ?? '';
    _lastNameController.text = profileData['lastName']?.toString() ?? '';
    _mobileController.text = profileData['mobile']?.toString() ?? '';
    _emailController.text = profileData['email']?.toString() ?? '';
  }

  void _hydrateSettings(Map<String, dynamic> settings) {
    if (settings.isEmpty) {
      return;
    }
    final version = settings['updatedAt']?.toString() ??
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

    _theme = preferences['theme']?.toString() ?? 'system';
    _language = preferences['language']?.toString() ?? 'en';
    _timezone = preferences['timezone']?.toString() ?? 'Asia/Calcutta';
    _defaultDashboard = dashboardLayout['defaultView']?.toString() ?? 'overview';
    _availabilityMode = availability['mode']?.toString() ?? 'FIELD';
    _availableForAssignments = availability['availableForAssignments'] != false;
    _followUpReminders = notifications['followUpReminders'] != false;
    _appointmentChanges = notifications['appointmentChanges'] != false;
    _referralUpdates = notifications['referralUpdates'] != false;
    _membershipReminders = notifications['membershipReminders'] != false;
    _showCustomerCodes = profilePreferences['showCustomerCodes'] != false;
    _showMembershipBadges = profilePreferences['showMembershipBadges'] != false;
    _allowPushNotifications = devicePreferences['allowPushNotifications'] != false;
    _requestedBranchId = requestedBranch['businessId']?.toString();
    _workingAreaController.text = workingArea['label']?.toString() ?? '';
    _workingDistrictController.text = workingArea['district']?.toString() ?? '';
    _travelRadiusController.text =
        workingArea['travelRadiusKm']?.toString() ?? '15';
    _emergencyNameController.text =
        emergencyContact['name']?.toString() ?? '';
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
    final messenger = ScaffoldMessenger.of(context);
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            controller.error?.toString() ?? 'Unable to update the profile.',
          ),
        ),
      );
    }
  }

  Future<void> _saveSettings(dynamic controller) async {
    final messenger = ScaffoldMessenger.of(context);
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
          'dashboardLayout': {
            'defaultView': _defaultDashboard,
          },
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Settings updated successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            controller.error?.toString() ?? 'Unable to update the settings.',
          ),
        ),
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
    final display = Map<String, dynamic>.from(authProfile['display'] ?? const {});
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

    final tabs = widget.profileOnly
        ? const ['Account', 'Preferences', 'Sessions']
        : const ['Account', 'Preferences', 'Branch', 'Sessions'];

    return DefaultTabController(
      length: tabs.length,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AgentSectionHeader(
                title: widget.profileOnly ? 'My Account' : 'Settings',
                description: widget.profileOnly
                    ? 'Personal details, account preferences, and active sessions now live in one place so profile and settings no longer feel like duplicate forms.'
                    : 'Manage account details, preferences, branch lifecycle, and session controls from one denser workspace instead of multiple whitespace-heavy screens.',
              ),
              const SizedBox(height: 12),
              _AccountSummaryCard(
                display: display,
                branchLifecycle: branchLifecycle,
                workingAreaLabel: _workingAreaController.text.trim(),
                availabilityMode: _availabilityMode,
                activeSessions: controller.sessions.length,
              ),
              const SizedBox(height: 12),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: tabs.map((label) => Tab(text: label)).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 820,
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _SettingsSectionCard(
                            title: 'Personal details',
                            subtitle:
                                'Keep contact details current without mixing them into the rest of the settings.',
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'First name',
                                    ),
                                  ),
                                ),
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Last name',
                                    ),
                                  ),
                                ),
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _mobileController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone',
                                    ),
                                  ),
                                ),
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsSectionCard(
                            title: 'Account status',
                            subtitle:
                                'A quick snapshot so the page does not feel empty on larger screens.',
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _MetricTile(
                                  value: display['employeeCode']?.toString() ?? '-',
                                  label: 'Employee code',
                                ),
                                _MetricTile(
                                  value: display['designation']?.toString() ??
                                      'Field Agent',
                                  label: 'Role',
                                ),
                                _MetricTile(
                                  value: _availableForAssignments
                                      ? 'Active'
                                      : 'Paused',
                                  label: 'Assignments',
                                ),
                                _MetricTile(
                                  value: _workingAreaController.text
                                      .trim()
                                      .ifBlank('Not set'),
                                  label: 'Working area',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: controller.isProfileSaving
                                  ? null
                                  : () => _saveProfile(controller),
                              child: Text(
                                controller.isProfileSaving
                                    ? 'Saving...'
                                    : 'Save Profile',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _SettingsSectionCard(
                            title: 'Appearance and workflow',
                            subtitle:
                                'Keep the operational defaults together so agents can adjust the experience without hunting through separate forms.',
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _AdaptiveField(
                                  child: DropdownButtonFormField<String>(
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
                                _AdaptiveField(
                                  child: DropdownButtonFormField<String>(
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
                                _AdaptiveField(
                                  child: DropdownButtonFormField<String>(
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
                                _AdaptiveField(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _defaultDashboard,
                                    decoration: const InputDecoration(
                                      labelText: 'Default dashboard',
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
                                _AdaptiveField(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _availabilityMode,
                                    decoration: const InputDecoration(
                                      labelText: 'Availability mode',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'FIELD',
                                        child: Text('Field'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'REMOTE',
                                        child: Text('Remote'),
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
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _deviceLabelController,
                                    decoration: const InputDecoration(
                                      labelText: 'Preferred device label',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsSectionCard(
                            title: 'Notifications and display',
                            subtitle:
                                'Keep reminder, badge, and push preferences compact instead of scattering them across separate pages.',
                            child: Column(
                              children: [
                                SwitchListTile(
                                  value: _availableForAssignments,
                                  onChanged: controller.isProfileSaving
                                      ? null
                                      : (value) => setState(
                                            () => _availableForAssignments =
                                                value,
                                          ),
                                  title: const Text(
                                    'Available for new assignments',
                                  ),
                                ),
                                SwitchListTile(
                                  value: _allowPushNotifications,
                                  onChanged: controller.isProfileSaving
                                      ? null
                                      : (value) => setState(
                                            () => _allowPushNotifications =
                                                value,
                                          ),
                                  title:
                                      const Text('Allow push notifications'),
                                ),
                                SwitchListTile(
                                  value: _followUpReminders,
                                  onChanged: controller.isProfileSaving
                                      ? null
                                      : (value) => setState(
                                            () => _followUpReminders = value,
                                          ),
                                  title: const Text('Follow-up reminders'),
                                ),
                                SwitchListTile(
                                  value: _appointmentChanges,
                                  onChanged: controller.isProfileSaving
                                      ? null
                                      : (value) => setState(
                                            () => _appointmentChanges = value,
                                          ),
                                  title:
                                      const Text('Appointment change alerts'),
                                ),
                                SwitchListTile(
                                  value: _referralUpdates,
                                  onChanged: controller.isProfileSaving
                                      ? null
                                      : (value) => setState(
                                            () => _referralUpdates = value,
                                          ),
                                  title: const Text('Network update alerts'),
                                ),
                                SwitchListTile(
                                  value: _membershipReminders,
                                  onChanged: controller.isProfileSaving
                                      ? null
                                      : (value) => setState(
                                            () => _membershipReminders = value,
                                          ),
                                  title:
                                      const Text('Membership reminder alerts'),
                                ),
                                SwitchListTile(
                                  value: _showCustomerCodes,
                                  onChanged: controller.isProfileSaving
                                      ? null
                                      : (value) => setState(
                                            () => _showCustomerCodes = value,
                                          ),
                                  title: const Text(
                                    'Show customer codes by default',
                                  ),
                                ),
                                SwitchListTile(
                                  value: _showMembershipBadges,
                                  onChanged: controller.isProfileSaving
                                      ? null
                                      : (value) => setState(
                                            () => _showMembershipBadges = value,
                                          ),
                                  title: const Text('Show membership badges'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsSectionCard(
                            title: 'Working area and emergency contact',
                            subtitle:
                                'Operational details stay editable here without crowding the account tab.',
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _workingStartController,
                                    decoration: const InputDecoration(
                                      labelText: 'Working hours start',
                                    ),
                                  ),
                                ),
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _workingEndController,
                                    decoration: const InputDecoration(
                                      labelText: 'Working hours end',
                                    ),
                                  ),
                                ),
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _workingAreaController,
                                    decoration: const InputDecoration(
                                      labelText: 'Working area label',
                                    ),
                                  ),
                                ),
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _workingDistrictController,
                                    decoration: const InputDecoration(
                                      labelText: 'District',
                                    ),
                                  ),
                                ),
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _travelRadiusController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Travel radius (km)',
                                    ),
                                  ),
                                ),
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _emergencyNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Emergency contact name',
                                    ),
                                  ),
                                ),
                                _AdaptiveField(
                                  child: TextField(
                                    controller: _emergencyPhoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Emergency contact phone',
                                    ),
                                  ),
                                ),
                                _AdaptiveField(
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
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: controller.isProfileSaving
                                  ? null
                                  : () => _saveSettings(controller),
                              child: Text(
                                controller.isProfileSaving
                                    ? 'Saving...'
                                    : 'Save Preferences',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.profileOnly)
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            _SettingsSectionCard(
                              title: 'Branch lifecycle',
                              subtitle:
                                  'Track active branch assignment and request changes without a separate admin-style page.',
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: safeRequestedBranchId,
                                    decoration: const InputDecoration(
                                      labelText:
                                          'Request transfer or assign branch',
                                    ),
                                    items: branches
                                        .map(
                                          (branch) => DropdownMenuItem<String>(
                                            value:
                                                branch['id']?.toString() ?? '',
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
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _branchNotesController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Branch request note',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (assignments.isEmpty)
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'No branch lifecycle history is available yet.',
                                      ),
                                    )
                                  else
                                    ...assignments.map(
                                      (assignment) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          assignment['business'] is Map
                                              ? (assignment['business']
                                                          as Map)['name']
                                                      ?.toString() ??
                                                  'Branch'
                                              : 'Branch',
                                        ),
                                        subtitle: Text(
                                          'Status: ${assignment['status'] ?? 'PENDING'}'
                                          '${assignment['notes']?.toString().isNotEmpty == true ? ' • ${assignment['notes']}' : ''}',
                                        ),
                                        trailing: assignment['isPrimary'] == true
                                            ? const Text('Primary')
                                            : null,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: controller.isProfileSaving
                                    ? null
                                    : () => _saveSettings(controller),
                                child: Text(
                                  controller.isProfileSaving
                                      ? 'Saving...'
                                      : 'Save Branch Request',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _SettingsSectionCard(
                            title: 'Session controls',
                            subtitle:
                                'Security and session actions stay visible here instead of being split between profile and settings.',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton(
                                  onPressed:
                                      InternalAuthSession.instance.signOut,
                                  child: const Text('Sign Out'),
                                ),
                                OutlinedButton(
                                  onPressed: controller.isSettingsLoading
                                      ? null
                                      : () => ref
                                          .read(agentPortalControllerProvider)
                                          .revokeOtherOwnedSessions(),
                                  child: const Text('Sign Out Other Devices'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsSectionCard(
                            title: 'Active sessions',
                            subtitle:
                                'See where the account is currently signed in.',
                            child: controller.sessions.isEmpty
                                ? const Text(
                                    'No active session history is available yet.',
                                  )
                                : Column(
                                    children: controller.sessions
                                        .map(
                                          (session) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              session['device']?['deviceName']
                                                      ?.toString() ??
                                                  'Session',
                                            ),
                                            subtitle: Text(
                                              session['loginMethod']
                                                      ?.toString() ??
                                                  'Internal login',
                                            ),
                                            trailing: session['isCurrent'] ==
                                                    true
                                                ? const Text('Current')
                                                : TextButton(
                                                    onPressed: () => ref
                                                        .read(
                                                          agentPortalControllerProvider,
                                                        )
                                                        .revokeOwnedSession(
                                                          session['sessionId']
                                                                  ?.toString() ??
                                                              '',
                                                        ),
                                                    child: const Text('Revoke'),
                                                  ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsSectionCard(
                            title: 'Login history',
                            subtitle:
                                'Recent access activity for quick review.',
                            child: controller.loginHistory.isEmpty
                                ? const Text(
                                    'No login history is available yet.',
                                  )
                                : Column(
                                    children: controller.loginHistory
                                        .take(10)
                                        .map(
                                          (row) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              row['status']?.toString() ??
                                                  'Status unavailable',
                                            ),
                                            subtitle: Text(
                                              row['createdAt']?.toString() ?? '',
                                            ),
                                            trailing: Text(
                                              row['loginMethod']
                                                      ?.toString() ??
                                                  '',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard({
    required this.display,
    required this.branchLifecycle,
    required this.workingAreaLabel,
    required this.availabilityMode,
    required this.activeSessions,
  });

  final Map<String, dynamic> display;
  final Map<String, dynamic> branchLifecycle;
  final String workingAreaLabel;
  final String availabilityMode;
  final int activeSessions;

  @override
  Widget build(BuildContext context) {
    final currentBranch = branchLifecycle['activeBranch'] is Map
        ? (branchLifecycle['activeBranch'] as Map)['name']?.toString()
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MetricTile(
            value: display['fullName']?.toString() ?? 'SHIELD Agent',
            label: display['designation']?.toString() ?? 'Field Agent',
          ),
          _MetricTile(
            value: display['employeeCode']?.toString() ?? '-',
            label: 'Employee code',
          ),
          _MetricTile(
            value: currentBranch?.ifBlank('Pending assignment') ??
                'Pending assignment',
            label: 'Branch',
          ),
          _MetricTile(
            value: workingAreaLabel.ifBlank('Not set'),
            label: 'Working area',
          ),
          _MetricTile(
            value: availabilityMode,
            label: 'Availability',
          ),
          _MetricTile(
            value: '$activeSessions',
            label: 'Active sessions',
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaptiveField extends StatelessWidget {
  const _AdaptiveField({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 280, child: child);
  }
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
