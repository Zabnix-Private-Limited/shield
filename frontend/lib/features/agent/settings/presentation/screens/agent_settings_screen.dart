import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/services/internal_auth_session.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';

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
    final requestedBranch =
        branchLifecycle['requestedBranch'] is Map
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
    _allowPushNotifications =
        devicePreferences['allowPushNotifications'] != false;
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
            'travelRadiusKm': int.tryParse(_travelRadiusController.text.trim()) ?? 15,
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

  Widget _buildChoiceGrid({
    required List<Widget> children,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return Column(
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 12),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: 280, child: child))
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final authProfile = controller.authProfile;
    final settings =
        controller.agentSettings.isNotEmpty
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
      ((settings['lookups'] as Map?)?['branches'] as List? ?? const <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    final safeRequestedBranchId =
        branches.any((branch) => branch['id']?.toString() == _requestedBranchId)
            ? _requestedBranchId
            : null;

    _hydrateProfile(authProfile);
    _hydrateSettings(settings);

    if (!widget.profileOnly &&
        !controller.isSettingsLoading &&
        controller.agentSettings.isEmpty) {
      Future.microtask(
        () => ref.read(agentPortalControllerProvider).loadSettingsData(),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.profileOnly ? 'Agent profile' : 'Profile and settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${display['fullName'] ?? 'SHIELD Agent'}'),
              subtitle: Text('${display['designation'] ?? 'Field Agent'}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Employee code'),
              trailing: Text('${display['employeeCode'] ?? '-'}'),
            ),
            _buildChoiceGrid(
              children: [
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                TextField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed:
                    controller.isProfileSaving ? null : () => _saveProfile(controller),
                child: Text(
                  controller.isProfileSaving ? 'Saving...' : 'Save profile',
                ),
              ),
            ),
            if (!widget.profileOnly) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Agent preferences',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildChoiceGrid(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _theme,
                    decoration: const InputDecoration(labelText: 'Theme'),
                    items: const [
                      DropdownMenuItem(
                        value: 'system',
                        child: Text('Use device setting'),
                      ),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged:
                        controller.isProfileSaving
                            ? null
                            : (value) =>
                                setState(() => _theme = value ?? 'system'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _language,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ml', child: Text('Malayalam')),
                      DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                    ],
                    onChanged:
                        controller.isProfileSaving
                            ? null
                            : (value) => setState(() => _language = value ?? 'en'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _timezone,
                    decoration: const InputDecoration(labelText: 'Timezone'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Asia/Calcutta',
                        child: Text('India Standard Time'),
                      ),
                      DropdownMenuItem(
                        value: 'Asia/Dubai',
                        child: Text('Gulf Standard Time'),
                      ),
                      DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                    ],
                    onChanged:
                        controller.isProfileSaving
                            ? null
                            : (value) => setState(
                                () => _timezone = value ?? 'Asia/Calcutta',
                              ),
                  ),
                  DropdownButtonFormField<String>(
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
                    onChanged:
                        controller.isProfileSaving
                            ? null
                            : (value) => setState(
                                () => _defaultDashboard = value ?? 'overview',
                              ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _availabilityMode,
                    decoration: const InputDecoration(
                      labelText: 'Availability mode',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'FIELD', child: Text('Field')),
                      DropdownMenuItem(value: 'REMOTE', child: Text('Remote')),
                      DropdownMenuItem(value: 'HYBRID', child: Text('Hybrid')),
                    ],
                    onChanged:
                        controller.isProfileSaving
                            ? null
                            : (value) => setState(
                                () => _availabilityMode = value ?? 'FIELD',
                              ),
                  ),
                  TextField(
                    controller: _deviceLabelController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred device label',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _availableForAssignments,
                onChanged:
                    controller.isProfileSaving
                        ? null
                        : (value) =>
                            setState(() => _availableForAssignments = value),
                title: const Text('Available for new assignments'),
                subtitle: const Text(
                  'Pause new customer assignments without signing out.',
                ),
              ),
              SwitchListTile(
                value: _allowPushNotifications,
                onChanged:
                    controller.isProfileSaving
                        ? null
                        : (value) =>
                            setState(() => _allowPushNotifications = value),
                title: const Text('Allow push notifications'),
              ),
              SwitchListTile(
                value: _followUpReminders,
                onChanged:
                    controller.isProfileSaving
                        ? null
                        : (value) => setState(() => _followUpReminders = value),
                title: const Text('Follow-up reminders'),
              ),
              SwitchListTile(
                value: _appointmentChanges,
                onChanged:
                    controller.isProfileSaving
                        ? null
                        : (value) =>
                            setState(() => _appointmentChanges = value),
                title: const Text('Appointment change alerts'),
              ),
              SwitchListTile(
                value: _referralUpdates,
                onChanged:
                    controller.isProfileSaving
                        ? null
                        : (value) => setState(() => _referralUpdates = value),
                title: const Text('Referral update alerts'),
              ),
              SwitchListTile(
                value: _membershipReminders,
                onChanged:
                    controller.isProfileSaving
                        ? null
                        : (value) =>
                            setState(() => _membershipReminders = value),
                title: const Text('Membership reminder alerts'),
              ),
              SwitchListTile(
                value: _showCustomerCodes,
                onChanged:
                    controller.isProfileSaving
                        ? null
                        : (value) => setState(() => _showCustomerCodes = value),
                title: const Text('Show customer codes by default'),
              ),
              SwitchListTile(
                value: _showMembershipBadges,
                onChanged:
                    controller.isProfileSaving
                        ? null
                        : (value) =>
                            setState(() => _showMembershipBadges = value),
                title: const Text('Show membership badges'),
              ),
              const SizedBox(height: 12),
              _buildChoiceGrid(
                children: [
                  TextField(
                    controller: _workingStartController,
                    decoration: const InputDecoration(
                      labelText: 'Working hours start',
                    ),
                  ),
                  TextField(
                    controller: _workingEndController,
                    decoration: const InputDecoration(
                      labelText: 'Working hours end',
                    ),
                  ),
                  TextField(
                    controller: _workingAreaController,
                    decoration: const InputDecoration(
                      labelText: 'Working area label',
                    ),
                  ),
                  TextField(
                    controller: _workingDistrictController,
                    decoration: const InputDecoration(labelText: 'District'),
                  ),
                  TextField(
                    controller: _travelRadiusController,
                    decoration: const InputDecoration(
                      labelText: 'Travel radius (km)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _emergencyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency contact name',
                    ),
                  ),
                  TextField(
                    controller: _emergencyPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency contact phone',
                    ),
                  ),
                  TextField(
                    controller: _emergencyRelationController,
                    decoration: const InputDecoration(labelText: 'Relationship'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Branch lifecycle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: safeRequestedBranchId,
                decoration: const InputDecoration(
                  labelText: 'Request transfer / assign branch',
                ),
                items: branches
                    .map(
                      (branch) => DropdownMenuItem<String>(
                        value: branch['id']?.toString(),
                        child: Text(
                          '${branch['name'] ?? 'Branch'} (${branch['code'] ?? '-'})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged:
                    controller.isProfileSaving
                        ? null
                        : (value) => setState(() => _requestedBranchId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _branchNotesController,
                decoration: const InputDecoration(
                  labelText: 'Branch request note',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              if (assignments.isEmpty)
                const Text('No branch lifecycle history is available yet.')
              else
                ...assignments.map(
                  (assignment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      assignment['business'] is Map
                          ? (assignment['business'] as Map)['name']?.toString() ??
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
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed:
                      controller.isProfileSaving
                          ? null
                          : () => _saveSettings(controller),
                  child: Text(
                    controller.isProfileSaving ? 'Saving...' : 'Save settings',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Session management',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: InternalAuthSession.instance.signOut,
                child: const Text('Sign out'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed:
                    controller.isSettingsLoading
                        ? null
                        : () => ref
                            .read(agentPortalControllerProvider)
                            .revokeOtherOwnedSessions(),
                child: const Text('Sign out other devices'),
              ),
              const SizedBox(height: 16),
              Text(
                'Active sessions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (controller.sessions.isEmpty)
                const Text('No active session history is available yet.')
              else
                ...controller.sessions.map(
                  (session) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      session['device']?['deviceName']?.toString() ?? 'Session',
                    ),
                    subtitle: Text(
                      session['loginMethod']?.toString() ?? 'Internal login',
                    ),
                    trailing:
                        session['isCurrent'] == true
                            ? const Text('Current')
                            : TextButton(
                                onPressed: () => ref
                                    .read(agentPortalControllerProvider)
                                    .revokeOwnedSession(
                                      session['sessionId']?.toString() ?? '',
                                    ),
                                child: const Text('Revoke'),
                              ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Login history',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (controller.loginHistory.isEmpty)
                const Text('No login history is available yet.')
              else
                ...controller.loginHistory.take(10).map(
                  (row) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row['status']?.toString() ?? 'Status unavailable'),
                    subtitle: Text(row['createdAt']?.toString() ?? ''),
                    trailing: Text(row['loginMethod']?.toString() ?? ''),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
