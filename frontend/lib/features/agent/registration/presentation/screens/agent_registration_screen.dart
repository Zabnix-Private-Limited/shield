import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentRegistrationScreen extends ConsumerStatefulWidget {
  const AgentRegistrationScreen({super.key});

  @override
  ConsumerState<AgentRegistrationScreen> createState() => _AgentRegistrationScreenState();
}

class _AgentRegistrationScreenState extends ConsumerState<AgentRegistrationScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _genderController = TextEditingController(text: 'MALE');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final authProfile = controller.authProfile;
    final display = Map<String, dynamic>.from(authProfile['display'] ?? const {});
    final employeeCode = display['employeeCode']?.toString() ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agent code: ${employeeCode.isEmpty ? 'Unavailable' : employeeCode}'),
            const SizedBox(height: 16),
            TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First name')),
            const SizedBox(height: 12),
            TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last name')),
            const SizedBox(height: 12),
            TextField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile')),
            const SizedBox(height: 12),
            TextField(controller: _genderController, decoration: const InputDecoration(labelText: 'Gender')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: employeeCode.isEmpty
                  ? null
                  : () => ref.read(agentPortalControllerProvider).createCustomer({
                        'first_name': _firstNameController.text.trim(),
                        'last_name': _lastNameController.text.trim(),
                        'mobile': _mobileController.text.trim(),
                        'gender': _genderController.text.trim(),
                        'agent_code': employeeCode,
                      }),
              child: const Text('Create customer'),
            ),
          ],
        ),
      ),
    );
  }
}
