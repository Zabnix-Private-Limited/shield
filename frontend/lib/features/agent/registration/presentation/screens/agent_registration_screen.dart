import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/prescription_file_picker.dart';
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
  final _emailController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _referralController = TextEditingController();
  final _addressController = TextEditingController();
  String _gender = 'MALE';
  String? _membershipTypeCode;
  String? _draftCustomerId;
  String? _selectedBusinessId;
  int _uploadedDocumentCount = 0;

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
    _aadhaarController.dispose();
    _referralController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _progress {
    var completed = 0;
    const total = 6;
    if (_firstNameController.text.trim().isNotEmpty) completed++;
    if (_mobileController.text.trim().isNotEmpty) completed++;
    if (_aadhaarController.text.trim().isNotEmpty) completed++;
    if (_addressController.text.trim().isNotEmpty) completed++;
    if ((_membershipTypeCode ?? '').isNotEmpty) completed++;
    if (_uploadedDocumentCount > 0) completed++;
    return completed / total;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final authProfile = controller.authProfile;
    final display = Map<String, dynamic>.from(authProfile['display'] ?? const {});
    final employeeCode = display['employeeCode']?.toString() ?? '';
    final membershipTypes = controller.membershipTypes;
    final businesses = controller.businesses;
    final drafts = controller.customers
        .where(
          (customer) => ['PENDING', 'INCOMPLETE', 'REJECTED'].contains(
            (customer['status'] ?? '').toString().toUpperCase(),
          ),
        )
        .toList();

    _membershipTypeCode ??=
        membershipTypes.isNotEmpty ? membershipTypes.first['code']?.toString() : null;
    _selectedBusinessId ??=
        businesses.isNotEmpty ? businesses.first['id']?.toString() : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer onboarding', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Agent code attached automatically: ${employeeCode.isEmpty ? 'Unavailable' : employeeCode}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('Progress ${(_progress * 100).round()}%'),
            const SizedBox(height: 16),
            if (drafts.isNotEmpty)
              DropdownButtonFormField<String>(
                key: ValueKey(_draftCustomerId),
                initialValue: _draftCustomerId,
                decoration: const InputDecoration(labelText: 'Continue existing draft'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Start a new registration'),
                  ),
                  ...drafts.map(
                    (draft) => DropdownMenuItem<String>(
                      value: draft['id']?.toString(),
                      child: Text(
                        '${draft['fullName'] ?? 'Customer'} • ${draft['mobile'] ?? ''} • ${_humanize(draft['status'])}',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _draftCustomerId = value);
                  if (value == null) {
                    return;
                  }
                  final selected = drafts.firstWhere(
                    (item) => item['id']?.toString() == value,
                    orElse: () => <String, dynamic>{},
                  );
                  _firstNameController.text = selected['fullName']
                          ?.toString()
                          .split(' ')
                          .firstOrNull ??
                      '';
                  _lastNameController.text = selected['fullName']
                          ?.toString()
                          .split(' ')
                          .skip(1)
                          .join(' ') ??
                      '';
                  _mobileController.text = selected['mobile']?.toString() ?? '';
                },
              ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 900;
                final form = _buildForm(membershipTypes, businesses);
                final side = _buildChecklist(context);
                if (stack) {
                  return Column(children: [form, const SizedBox(height: 16), side]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: form),
                    const SizedBox(width: 16),
                    Expanded(child: side),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  onPressed: employeeCode.isEmpty
                      ? null
                      : () => _saveRegistration(controller, submit: false),
                  child: const Text('Save draft'),
                ),
                FilledButton(
                  onPressed: employeeCode.isEmpty
                      ? null
                      : () => _saveRegistration(controller, submit: true),
                  child: const Text('Submit registration'),
                ),
                OutlinedButton(
                  onPressed: _draftCustomerId == null
                      ? null
                      : () async {
                          final file = await pickPrescriptionFile();
                          if (file == null) {
                            return;
                          }
                          await controller.uploadCustomerDocument(
                            customerId: _draftCustomerId!,
                            fileName: file.name,
                            documentType: 'ID_PROOF',
                            fileBytes: file.bytes,
                            mimeType: file.mimeType ?? 'application/octet-stream',
                            fileSize: file.size,
                          );
                          setState(() => _uploadedDocumentCount += 1);
                        },
                  child: const Text('Upload required document'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Branch assignment is still approval-owned in the current live schema. The selected branch below is captured for agent workflow context, but the actual issued branch remains controlled during approval.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    List<Map<String, dynamic>> membershipTypes,
    List<Map<String, dynamic>> businesses,
  ) {
    return Column(
      children: [
        TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First name')),
        const SizedBox(height: 12),
        TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last name')),
        const SizedBox(height: 12),
        TextField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 12),
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(controller: _aadhaarController, decoration: const InputDecoration(labelText: 'ID number')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_gender),
          initialValue: _gender,
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
          ],
          onChanged: (value) => setState(() => _gender = value ?? 'MALE'),
          decoration: const InputDecoration(labelText: 'Gender'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_membershipTypeCode),
          initialValue: _membershipTypeCode,
          items: membershipTypes
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item['code']?.toString(),
                  child: Text(item['name']?.toString() ?? item['code']?.toString() ?? 'Membership'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _membershipTypeCode = value),
          decoration: const InputDecoration(labelText: 'Membership selection'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedBusinessId),
          initialValue: _selectedBusinessId,
          items: businesses
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item['id']?.toString(),
                  child: Text(item['name']?.toString() ?? 'Branch'),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedBusinessId = value),
          decoration: const InputDecoration(labelText: 'Preferred branch assignment'),
        ),
        const SizedBox(height: 12),
        TextField(controller: _referralController, decoration: const InputDecoration(labelText: 'Referral code (optional)')),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Address'),
        ),
      ],
    );
  }

  Widget _buildChecklist(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Onboarding checklist', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _CheckItem(label: 'Basic profile details', done: _firstNameController.text.trim().isNotEmpty && _mobileController.text.trim().isNotEmpty),
            _CheckItem(label: 'Identity number', done: _aadhaarController.text.trim().isNotEmpty),
            _CheckItem(label: 'Membership selected', done: (_membershipTypeCode ?? '').isNotEmpty),
            _CheckItem(label: 'Preferred branch noted', done: (_selectedBusinessId ?? '').isNotEmpty),
            _CheckItem(label: 'Required document uploaded', done: _uploadedDocumentCount > 0),
            const SizedBox(height: 12),
            Text('Current status: ${_draftCustomerId == null ? 'New registration' : 'Continuing draft'}'),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRegistration(dynamic controller, {required bool submit}) async {
    final payload = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'email': _emailController.text.trim(),
      'aadhaar_number': _aadhaarController.text.trim(),
      'gender': _gender,
      'address_line1': _addressController.text.trim(),
      'referred_by_code': _referralController.text.trim(),
      'membership_type_code': _membershipTypeCode,
      'status': submit ? 'PENDING' : 'INCOMPLETE',
    };

    if (_draftCustomerId == null) {
      await controller.createCustomer(payload);
      final selectedId = controller.selectedCustomerId?.toString();
      if (selectedId != null && selectedId.isNotEmpty) {
        setState(() => _draftCustomerId = selectedId);
      }
      return;
    }

    await controller.updateCustomer(customerId: _draftCustomerId!, payload: payload);
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

String _humanize(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) {
    return 'Pending';
  }
  return text
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

extension _FirstOrNull on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
