import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_typography.dart';
import '../../../../../../shared/services/internal_auth_session.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderSettingsScreen extends StatefulWidget {
  const ProviderSettingsScreen({super.key});

  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
  bool _appointmentChanges = true;
  bool _visitUpdates = true;
  bool _prescriptionUpdates = true;
  bool _billingUpdates = true;
  bool _autoOpenPdf = true;
  bool _includeSignature = true;
  String _theme = 'system';
  String _language = 'en';
  String _timezone = 'Asia/Calcutta';
  String _paperSize = 'A4';
  String _defaultPrinter = '';
  String? _profileVersion;
  final TextEditingController _defaultPrinterController =
      TextEditingController();

  @override
  void dispose() {
    _defaultPrinterController.dispose();
    super.dispose();
  }

  void _hydratePreferences(Map<String, dynamic> profile) {
    final version =
        profile['updatedAt']?.toString() ??
        profile['profileId']?.toString() ??
        'provider-preferences';
    if (_profileVersion == version) {
      return;
    }

    final preferences =
        profile['preferences'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final notifications =
        preferences['notifications'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final print =
        preferences['print'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    _appointmentChanges = notifications['appointmentChanges'] != false;
    _visitUpdates = notifications['visitUpdates'] != false;
    _prescriptionUpdates = notifications['prescriptionUpdates'] != false;
    _billingUpdates = notifications['billingUpdates'] != false;
    _theme = preferences['theme']?.toString() ?? 'system';
    _language = preferences['language']?.toString() ?? 'en';
    _timezone = preferences['timezone']?.toString() ?? 'Asia/Calcutta';
    _defaultPrinter = preferences['defaultPrinter']?.toString() ?? '';
    _defaultPrinterController.text = _defaultPrinter;
    _autoOpenPdf = print['autoOpenPdf'] != false;
    _includeSignature = print['includeSignature'] != false;
    _paperSize = print['paperSize']?.toString() ?? 'A4';
    _profileVersion = version;
  }

  Future<void> _savePreferences(BuildContext context, dynamic controller) async {
    final messenger = ScaffoldMessenger.of(context);
    final payload = <String, dynamic>{
      'notifications': {
        'appointmentChanges': _appointmentChanges,
        'visitUpdates': _visitUpdates,
        'prescriptionUpdates': _prescriptionUpdates,
        'billingUpdates': _billingUpdates,
      },
      'theme': _theme,
      'language': _language,
      'timezone': _timezone,
      'defaultPrinter': _defaultPrinterController.text.trim(),
      'print': {
        'autoOpenPdf': _autoOpenPdf,
        'includeSignature': _includeSignature,
        'paperSize': _paperSize,
      },
    };

    try {
      await controller.saveProviderPreferences(payload);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Settings updated.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(controller.error?.toString() ?? 'Unable to update settings.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      loadSettings: true,
      builder: (context, ref, controller) {
        final profile = controller.providerProfile;
        _hydratePreferences(profile);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: AppTypography.h4),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Preferences', style: AppTypography.h5),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _appointmentChanges,
                      onChanged: controller.isProviderProfileSaving
                          ? null
                          : (value) => setState(() => _appointmentChanges = value),
                      title: const Text('Appointment changes'),
                      subtitle: const Text(
                        'Notify me when bookings are created, moved, or cancelled.',
                      ),
                    ),
                    SwitchListTile(
                      value: _visitUpdates,
                      onChanged: controller.isProviderProfileSaving
                          ? null
                          : (value) => setState(() => _visitUpdates = value),
                      title: const Text('Visit updates'),
                      subtitle: const Text(
                        'Notify me when visits start, wait, or complete.',
                      ),
                    ),
                    SwitchListTile(
                      value: _prescriptionUpdates,
                      onChanged: controller.isProviderProfileSaving
                          ? null
                          : (value) => setState(() => _prescriptionUpdates = value),
                      title: const Text('Prescription updates'),
                      subtitle: const Text(
                        'Notify me after prescriptions are finalized.',
                      ),
                    ),
                    SwitchListTile(
                      value: _billingUpdates,
                      onChanged: controller.isProviderProfileSaving
                          ? null
                          : (value) => setState(() => _billingUpdates = value),
                      title: const Text('Billing updates'),
                      subtitle: const Text(
                        'Notify me for invoice, payment, and refund events.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _theme,
                            decoration: const InputDecoration(labelText: 'Theme'),
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
                            onChanged: controller.isProviderProfileSaving
                                ? null
                                : (value) => setState(
                                    () => _theme = value ?? 'system',
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                            onChanged: controller.isProviderProfileSaving
                                ? null
                                : (value) => setState(
                                    () => _language = value ?? 'en',
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
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
                            onChanged: controller.isProviderProfileSaving
                                ? null
                                : (value) => setState(
                                    () => _timezone = value ?? 'Asia/Calcutta',
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _defaultPrinterController,
                            decoration: const InputDecoration(
                              labelText: 'Default printer',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _autoOpenPdf,
                      onChanged: controller.isProviderProfileSaving
                          ? null
                          : (value) => setState(() => _autoOpenPdf = value),
                      title: const Text('Open print preview automatically'),
                    ),
                    SwitchListTile(
                      value: _includeSignature,
                      onChanged: controller.isProviderProfileSaving
                          ? null
                          : (value) => setState(() => _includeSignature = value),
                      title: const Text('Include digital signature on printouts'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _paperSize,
                      decoration: const InputDecoration(labelText: 'Paper size'),
                      items: const [
                        DropdownMenuItem(value: 'A4', child: Text('A4')),
                        DropdownMenuItem(value: 'LETTER', child: Text('Letter')),
                      ],
                      onChanged: controller.isProviderProfileSaving
                          ? null
                          : (value) => setState(() => _paperSize = value ?? 'A4'),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: controller.isProviderProfileSaving
                            ? null
                            : () => _savePreferences(context, controller),
                        child: Text(
                          controller.isProviderProfileSaving
                              ? 'Saving...'
                              : 'Save settings',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Session access', style: AppTypography.h5),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: InternalAuthSession.instance.signOut,
                      child: const Text('Sign out'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: controller.isSettingsLoading
                          ? null
                          : controller.revokeOtherOwnedSessions,
                      child: const Text('Sign out other devices'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Sessions', style: AppTypography.h5),
            const SizedBox(height: 8),
            ...controller.sessions.map(
              (session) => Card(
                child: ListTile(
                  title: Text(
                    session['device']?['deviceName']?.toString() ?? 'Session',
                  ),
                  subtitle: Text(session['loginMethod']?.toString() ?? ''),
                  trailing: session['isCurrent'] == true
                      ? const Text('Current')
                      : TextButton(
                          onPressed: () => controller.revokeOwnedSession(
                            session['sessionId']?.toString() ?? '',
                          ),
                          child: const Text('Revoke'),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Login history', style: AppTypography.h5),
            const SizedBox(height: 8),
            ...controller.loginHistory.map(
              (row) => Card(
                child: ListTile(
                  title: Text(row['status']?.toString() ?? 'Status unavailable'),
                  subtitle: Text(row['createdAt']?.toString() ?? ''),
                  trailing: Text(row['loginMethod']?.toString() ?? ''),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
