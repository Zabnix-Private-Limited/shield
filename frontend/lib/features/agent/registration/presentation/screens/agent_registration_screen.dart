import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/prescription_file_picker.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentRegistrationScreen extends ConsumerStatefulWidget {
  const AgentRegistrationScreen({super.key});

  @override
  ConsumerState<AgentRegistrationScreen> createState() =>
      _AgentRegistrationScreenState();
}

class _AgentRegistrationScreenState
    extends ConsumerState<AgentRegistrationScreen> {
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

  int get _currentStep {
    if (_uploadedDocumentCount > 0) {
      return 4;
    }
    if (_addressController.text.trim().isNotEmpty ||
        (_membershipTypeCode ?? '').isNotEmpty ||
        (_selectedBusinessId ?? '').isNotEmpty) {
      return 3;
    }
    if (_aadhaarController.text.trim().isNotEmpty) {
      return 2;
    }
    return 1;
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
            AgentSectionHeader(
              title: 'Register Customer',
              description:
                  'Capture the customer profile first, then identity, membership, and required documents in a clear field workflow.',
              actions: [
                OutlinedButton(
                  onPressed: employeeCode.isEmpty
                      ? null
                      : () => _saveRegistration(controller, submit: false),
                  child: const Text('Save Draft'),
                ),
                FilledButton(
                  onPressed: employeeCode.isEmpty
                      ? null
                      : () => _saveRegistration(controller, submit: true),
                  child: const Text('Register Customer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (drafts.isNotEmpty)
              DropdownButtonFormField<String>(
                key: ValueKey(_draftCustomerId),
                initialValue: _draftCustomerId,
                decoration: const InputDecoration(
                  labelText: 'Continue draft registration',
                ),
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
                  _firstNameController.text =
                      selected['fullName']?.toString().split(' ').firstOrNull ?? '';
                  _lastNameController.text = selected['fullName']
                          ?.toString()
                          .split(' ')
                          .skip(1)
                          .join(' ') ??
                      '';
                  _mobileController.text = selected['mobile']?.toString() ?? '';
                },
              ),
            if (drafts.isNotEmpty) const SizedBox(height: 16),
            _StepOverview(currentStep: _currentStep, uploadedDocuments: _uploadedDocumentCount),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 920;
                final form = Column(
                  children: [
                    _buildDetailsCard(),
                    const SizedBox(height: 16),
                    _buildIdentityCard(employeeCode),
                    const SizedBox(height: 16),
                    _buildMembershipCard(membershipTypes, businesses),
                    const SizedBox(height: 16),
                    _buildAddressCard(),
                  ],
                );
                final side = Column(
                  children: [
                    _buildWorkflowCard(employeeCode),
                    const SizedBox(height: 16),
                    _buildDocumentCard(controller),
                  ],
                );
                if (stack) {
                  return Column(children: [form, const SizedBox(height: 16), side]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: form),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: side),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return _FormCard(
      title: 'Customer Details',
      subtitle: 'Start with the contact details agents collect every day.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _fieldBox(
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
          ),
          _fieldBox(
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
          ),
          _fieldBox(
            TextField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ),
          _fieldBox(
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ),
          _fieldBox(
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
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(String employeeCode) {
    return _FormCard(
      title: 'Identity',
      subtitle:
          'Government identity stays editable, while the SHIELD customer ID is generated automatically after registration.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _fieldBox(
            TextFormField(
              readOnly: true,
              initialValue: _draftCustomerId == null
                  ? ''
                  : 'Generated for saved registration',
              decoration: const InputDecoration(
                labelText: 'SHIELD customer ID',
                hintText: 'Generated automatically after registration',
              ),
            ),
          ),
          _fieldBox(
            TextField(
              controller: _aadhaarController,
              decoration: const InputDecoration(
                labelText: 'Aadhaar / Government ID',
                hintText: 'Capture the customer identity number',
              ),
            ),
          ),
          _fieldBox(
            TextFormField(
              readOnly: true,
              initialValue: employeeCode.isEmpty
                  ? 'Agent code unavailable'
                  : employeeCode,
              decoration: const InputDecoration(labelText: 'Assigned agent'),
            ),
          ),
          _fieldBox(
            TextField(
              controller: _referralController,
              decoration: const InputDecoration(
                labelText: 'Customer network code (optional)',
                hintText: 'Link an existing customer relationship if available',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(
    List<Map<String, dynamic>> membershipTypes,
    List<Map<String, dynamic>> businesses,
  ) {
    return _FormCard(
      title: 'Membership',
      subtitle:
          'Choose the plan and working branch context before submitting the registration.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _fieldBox(
            DropdownButtonFormField<String>(
              key: ValueKey(_membershipTypeCode),
              initialValue: _membershipTypeCode,
              items: membershipTypes
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['code']?.toString(),
                      child: Text(
                        item['name']?.toString() ??
                            item['code']?.toString() ??
                            'Membership',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _membershipTypeCode = value),
              decoration: const InputDecoration(labelText: 'Membership plan'),
            ),
          ),
          _fieldBox(
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
              decoration: const InputDecoration(labelText: 'Preferred branch'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return _FormCard(
      title: 'Address',
      subtitle: 'Capture the location details needed for follow-ups and document collection.',
      child: TextField(
        controller: _addressController,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Address'),
      ),
    );
  }

  Widget _buildWorkflowCard(String employeeCode) {
    final checks = [
      _CheckItem(
        label: 'Customer details captured',
        done: _firstNameController.text.trim().isNotEmpty &&
            _mobileController.text.trim().isNotEmpty,
      ),
      _CheckItem(
        label: 'Identity captured',
        done: _aadhaarController.text.trim().isNotEmpty,
      ),
      _CheckItem(
        label: 'Membership selected',
        done: (_membershipTypeCode ?? '').isNotEmpty,
      ),
      _CheckItem(
        label: 'Preferred branch noted',
        done: (_selectedBusinessId ?? '').isNotEmpty,
      ),
      _CheckItem(
        label: 'Documents uploaded',
        done: _uploadedDocumentCount > 0,
      ),
    ];

    return _FormCard(
      title: 'Workflow Status',
      subtitle:
          'Primary action is registration. Document upload becomes available after the customer record exists.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned agent code: ${employeeCode.isEmpty ? 'Unavailable' : employeeCode}',
          ),
          const SizedBox(height: 12),
          ...checks,
          const SizedBox(height: 12),
          Text(
            'Current status: ${_draftCustomerId == null ? 'New registration' : 'Continuing saved draft'}',
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(dynamic controller) {
    return _FormCard(
      title: 'Required Documents',
      subtitle:
          'Upload after the customer draft exists so every file is attached to the correct customer record.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RequiredDocument(label: 'Aadhaar / Government ID'),
          const _RequiredDocument(label: 'Address Proof'),
          const _RequiredDocument(label: 'Profile Photo'),
          const _RequiredDocument(label: 'Prescription if available'),
          const SizedBox(height: 12),
          FilledButton.icon(
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
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(
              _draftCustomerId == null
                  ? 'Save draft before upload'
                  : 'Upload Documents',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Branch assignment remains approval-owned in the live schema, so the selected branch is captured for workflow context and finalized during approval.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _fieldBox(Widget child) {
    return SizedBox(width: 280, child: child);
  }

  Future<void> _saveRegistration(
    dynamic controller, {
    required bool submit,
  }) async {
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

    await controller.updateCustomer(
      customerId: _draftCustomerId!,
      payload: payload,
    );
  }
}

class _StepOverview extends StatelessWidget {
  const _StepOverview({
    required this.currentStep,
    required this.uploadedDocuments,
  });

  final int currentStep;
  final int uploadedDocuments;

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Customer Details',
      'Identity',
      'Membership & Branch',
      uploadedDocuments > 0 ? 'Completed' : 'Documents',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step $currentStep of 4',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(
                steps.length,
                (index) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      index + 1 < currentStep
                          ? Icons.check_circle
                          : index + 1 == currentStep
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(steps[index]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
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

class _RequiredDocument extends StatelessWidget {
  const _RequiredDocument({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_box_outline_blank, size: 18),
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
