import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/services/api_service.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final authProfile = controller.authProfile;
    final display = Map<String, dynamic>.from(authProfile['display'] ?? const {});
    final profile = Map<String, dynamic>.from(authProfile['profile'] ?? const {});

    _firstNameController.text = profile['firstName']?.toString() ?? '';
    _lastNameController.text = profile['lastName']?.toString() ?? '';
    _mobileController.text = profile['mobile']?.toString() ?? '';
    _emailController.text = profile['email']?.toString() ?? '';

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
            TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First name')),
            const SizedBox(height: 12),
            TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last name')),
            const SizedBox(height: 12),
            TextField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: controller.isProfileSaving
                    ? null
                    : () => ref.read(agentPortalControllerProvider).updateCurrentProfile({
                          'first_name': _firstNameController.text.trim(),
                          'last_name': _lastNameController.text.trim(),
                          'mobile': _mobileController.text.trim(),
                          'email': _emailController.text.trim(),
                        }),
                child: const Text('Save profile'),
              ),
            ),
            if (!widget.profileOnly) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text('Session management', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                'Theme, language, emergency contact, availability, and working-area persistence are still blocked by the current live schema. Session controls and editable identity details are operational now.',
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  await ApiService.revokeOtherSessions();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Other signed-in devices have been signed out.'),
                    ),
                  );
                },
                child: const Text('Sign out other devices'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
