import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/utils/prescription_file_picker.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_design_system.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentRegistrationScreen extends ConsumerStatefulWidget {
  const AgentRegistrationScreen({super.key});

  @override
  ConsumerState<AgentRegistrationScreen> createState() =>
      _AgentRegistrationScreenState();
}

class _AgentRegistrationScreenState
    extends ConsumerState<AgentRegistrationScreen> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _identityFormKey = GlobalKey<FormState>();
  final _membershipFormKey = GlobalKey<FormState>();
  final _documentsFormKey = GlobalKey<FormState>();

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
  int _currentStep = 0;
  bool _autoSaving = false;
  String _autoSaveMessage = 'Draft autosaves when you move between steps.';
  Timer? _saveMessageTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  void dispose() {
    _saveMessageTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _aadhaarController.dispose();
    _referralController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final authProfile = controller.authProfile;
    final display = Map<String, dynamic>.from(
      authProfile['display'] ?? const {},
    );
    final employeeCode = display['employeeCode']?.toString() ?? '';
    final membershipTypes = controller.membershipTypes;
    final businesses = controller.businesses;
    final drafts = controller.customers
        .where(
          (customer) => [
            'PENDING',
            'INCOMPLETE',
            'REJECTED',
          ].contains((customer['status'] ?? '').toString().toUpperCase()),
        )
        .toList();

    _membershipTypeCode ??= membershipTypes.isNotEmpty
        ? membershipTypes.first['code']?.toString()
        : null;
    _selectedBusinessId ??= businesses.isNotEmpty
        ? businesses.first['id']?.toString()
        : null;

    final progress = (_currentStep + 1) / 5;
    final bodyHeight = (MediaQuery.sizeOf(context).height - 280).clamp(
      320.0,
      1200.0,
    );

    return AgentWorkspaceSurface(
      padding: AgentSpacing.contentInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgentSectionHeader(
            title: 'Register Customer',
            description:
                'This onboarding flow now moves one responsibility at a time: personal details, identity, membership, documents, and then review before submission.',
            actions: [
              AgentSecondaryButton(
                onPressed: employeeCode.isEmpty
                    ? null
                    : () => _saveRegistration(
                        controller,
                        submit: false,
                        showFeedback: true,
                      ),
                label: _autoSaving ? 'Saving...' : 'Save Draft',
              ),
              AgentPrimaryButton(
                onPressed: employeeCode.isEmpty
                    ? null
                    : () async {
                        if (_currentStep < 4) {
                          final moved = await _goToNextStep(controller);
                          if (!moved || !mounted) {
                            return;
                          }
                        }
                        await _submitRegistration(controller);
                      },
                label: 'Register Customer',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (drafts.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              key: ValueKey(_draftCustomerId),
              initialValue: _draftCustomerId,
              decoration: const InputDecoration(
                labelText: 'Resume saved draft',
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
                  _resetForNewDraft();
                  return;
                }
                final selected = drafts.firstWhere(
                  (item) => item['id']?.toString() == value,
                  orElse: () => <String, dynamic>{},
                );
                _hydrateDraft(selected);
              },
            ),
            const SizedBox(height: 16),
          ],
          AgentPanelCard(
            title: 'Onboarding Progress',
            subtitle: _autoSaveMessage,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: progress, minHeight: 8),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(
                    _steps.length,
                    (index) => _StepChip(
                      label: _steps[index],
                      state: index < _currentStep
                          ? _StepChipState.complete
                          : index == _currentStep
                          ? _StepChipState.active
                          : _StepChipState.inactive,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: bodyHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: SingleChildScrollView(
                key: ValueKey(_currentStep),
                child: _RegistrationStepScaffold(
                  title: _steps[_currentStep],
                  subtitle: _stepSubtitle(_currentStep),
                  body: _buildCurrentStep(
                    context,
                    controller,
                    employeeCode,
                    membershipTypes,
                    businesses,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AgentSecondaryButton(
                onPressed: _currentStep == 0
                    ? null
                    : () => setState(() => _currentStep -= 1),
                label: 'Previous',
              ),
              const Spacer(),
              if (_currentStep < 4)
                AgentPrimaryButton(
                  onPressed: () => _goToNextStep(controller),
                  label: 'Next',
                )
              else
                AgentPrimaryButton(
                  onPressed: () => _submitRegistration(controller),
                  label: 'Submit Registration',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(
    BuildContext context,
    dynamic controller,
    String employeeCode,
    List<Map<String, dynamic>> membershipTypes,
    List<Map<String, dynamic>> businesses,
  ) {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _detailsFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: _StepContentCard(
            title: 'Customer Information',
            summary:
                'Capture the identity the agent already knows first: name, phone, email, and gender.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _fieldBox(
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter first name'
                        : null,
                  ),
                ),
                _fieldBox(
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                ),
                _fieldBox(
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Enter phone number';
                      }
                      if (text.length < 10) {
                        return 'Phone number looks incomplete';
                      }
                      return null;
                    },
                  ),
                ),
                _fieldBox(
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return null;
                      }
                      if (!text.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
                _fieldBox(
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    items: const [
                      DropdownMenuItem(value: 'MALE', child: Text('Male')),
                      DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (value) =>
                        setState(() => _gender = value ?? 'MALE'),
                    decoration: const InputDecoration(labelText: 'Gender'),
                  ),
                ),
              ],
            ),
          ),
        );
      case 1:
        return Form(
          key: _identityFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: _StepContentCard(
            title: 'Identity',
            summary:
                'The SHIELD customer ID is generated automatically. The only manual identity capture here is the government ID and optional network code.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _fieldBox(
                  TextFormField(
                    readOnly: true,
                    initialValue: _draftCustomerId == null
                        ? ''
                        : 'Generated after final registration',
                    decoration: const InputDecoration(
                      labelText: 'SHIELD customer ID',
                      hintText: 'Generated automatically after registration',
                    ),
                  ),
                ),
                _fieldBox(
                  TextFormField(
                    controller: _aadhaarController,
                    decoration: const InputDecoration(
                      labelText: 'Aadhaar / Government ID',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Capture the identity number'
                        : null,
                  ),
                ),
                _fieldBox(
                  TextFormField(
                    readOnly: true,
                    initialValue: employeeCode.isEmpty
                        ? 'Agent code unavailable'
                        : employeeCode,
                    decoration: const InputDecoration(
                      labelText: 'Assigned agent',
                    ),
                  ),
                ),
                _fieldBox(
                  TextFormField(
                    controller: _referralController,
                    decoration: const InputDecoration(
                      labelText: 'Customer network code (optional)',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case 2:
        return Form(
          key: _membershipFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: _StepContentCard(
            title: 'Membership and Branch',
            summary:
                'Choose the plan and branch now so the review step reads like a complete onboarding summary.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _fieldBox(
                      DropdownButtonFormField<String>(
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
                        onChanged: (value) =>
                            setState(() => _membershipTypeCode = value),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Choose membership plan'
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Membership plan',
                        ),
                      ),
                    ),
                    _fieldBox(
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBusinessId,
                        items: businesses
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item['id']?.toString(),
                                child: Text(
                                  item['name']?.toString() ?? 'Branch',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedBusinessId = value),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Choose branch'
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Preferred branch',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Address'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter address'
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case 3:
        final customerDocs = controller.customerDocuments;
        return Form(
          key: _documentsFormKey,
          child: _StepContentCard(
            title: 'Documents',
            summary:
                'Required files are attached only after the draft exists, which keeps documents linked to the right customer record.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _RequiredDocumentRow(
                      label: 'Aadhaar / Government ID',
                      done: customerDocs.any(
                        (doc) =>
                            (doc['documentType'] ?? '')
                                .toString()
                                .toUpperCase() ==
                            'ID_PROOF',
                      ),
                    ),
                    _RequiredDocumentRow(
                      label: 'Address Proof',
                      done: customerDocs.any(
                        (doc) =>
                            (doc['documentType'] ?? '')
                                .toString()
                                .toUpperCase() ==
                            'ADDRESS_PROOF',
                      ),
                    ),
                    _RequiredDocumentRow(
                      label: 'Profile Photo',
                      done: customerDocs.any(
                        (doc) =>
                            (doc['documentType'] ?? '')
                                .toString()
                                .toUpperCase() ==
                            'PROFILE_PHOTO',
                      ),
                    ),
                    _RequiredDocumentRow(
                      label: 'Prescription if available',
                      done: customerDocs.any(
                        (doc) =>
                            (doc['documentType'] ?? '')
                                .toString()
                                .toUpperCase() ==
                            'PRESCRIPTION',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AgentPrimaryButton(
                      onPressed: _draftCustomerId == null
                          ? null
                          : () => _uploadStepDocument(controller, 'ID_PROOF'),
                      icon: const Icon(Icons.upload_file_outlined),
                      label: _draftCustomerId == null
                          ? 'Save draft before upload'
                          : 'Upload Document',
                    ),
                    if (_draftCustomerId != null)
                      AgentSecondaryButton(
                        onPressed: () =>
                            setState(() => _uploadedDocumentCount = 0),
                        icon: const Icon(Icons.refresh_outlined),
                        label: 'Refresh progress',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                AgentPanelCard(
                  title: 'Uploaded in this draft',
                  subtitle:
                      'A quick summary before the final review and submission step.',
                  child: customerDocs.isEmpty
                      ? const AgentEmptyState(
                          icon: Icons.folder_open_outlined,
                          title: 'No files uploaded yet',
                          message:
                              'Upload the available customer documents now, or continue to review and finish the registration later.',
                        )
                      : Column(
                          children: customerDocs
                              .map(
                                (doc) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.description_outlined,
                                  ),
                                  title: Text(
                                    doc['fileName']?.toString() ?? 'Document',
                                  ),
                                  subtitle: Text(
                                    '${_humanize(doc['documentType'])} • ${_humanize(doc['status'])}',
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      default:
        return _StepContentCard(
          title: 'Review and Submit',
          summary:
              'Check the customer summary once before sending it for approval. This keeps the final action intentional instead of accidental.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewItem(
                label: 'Customer',
                value:
                    '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                        .trim()
                        .ifBlank('Not set'),
              ),
              _ReviewItem(
                label: 'Phone',
                value: _mobileController.text.trim().ifBlank('Not set'),
              ),
              _ReviewItem(
                label: 'Email',
                value: _emailController.text.trim().ifBlank('Not set'),
              ),
              _ReviewItem(
                label: 'Government ID',
                value: _aadhaarController.text.trim().ifBlank('Not set'),
              ),
              _ReviewItem(
                label: 'Membership plan',
                value:
                    _membershipTypeCode?.ifBlank('Not selected') ??
                    'Not selected',
              ),
              _ReviewItem(
                label: 'Preferred branch',
                value:
                    _selectedBusinessId?.ifBlank('Not selected') ??
                    'Not selected',
              ),
              _ReviewItem(
                label: 'Address',
                value: _addressController.text.trim().ifBlank('Not set'),
              ),
              _ReviewItem(
                label: 'Documents uploaded',
                value: '$_uploadedDocumentCount',
              ),
              const SizedBox(height: 16),
              AgentStatusBadge(
                label: _draftCustomerId == null
                    ? 'New registration'
                    : 'Saved draft ready to submit',
                color: _draftCustomerId == null
                    ? AgentColors.warning
                    : AgentColors.success,
                icon: _draftCustomerId == null
                    ? Icons.edit_note_outlined
                    : Icons.check_circle_outline,
              ),
            ],
          ),
        );
    }
  }

  Future<bool> _goToNextStep(dynamic controller) async {
    if (!_validateCurrentStep()) {
      return false;
    }
    await _autoSaveDraft(controller);
    if (!mounted) {
      return false;
    }
    setState(() => _currentStep = (_currentStep + 1).clamp(0, 4));
    return true;
  }

  Future<void> _submitRegistration(dynamic controller) async {
    if (!_validateAllSteps()) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Complete the missing registration details first.'),
        ),
      );
      return;
    }

    await _saveRegistration(controller, submit: true, showFeedback: true);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer registration submitted successfully.'),
      ),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _detailsFormKey.currentState?.validate() ?? false;
      case 1:
        return _identityFormKey.currentState?.validate() ?? false;
      case 2:
        return _membershipFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  bool _validateAllSteps() {
    final details = _detailsFormKey.currentState?.validate() ?? false;
    final identity = _identityFormKey.currentState?.validate() ?? false;
    final membership = _membershipFormKey.currentState?.validate() ?? false;
    return details && identity && membership;
  }

  Future<void> _autoSaveDraft(dynamic controller) async {
    if (!_validateCurrentStep()) {
      return;
    }
    _setAutoSaveState(true, 'Saving draft...');
    try {
      await _saveRegistration(controller, submit: false, showFeedback: false);
      _setAutoSaveState(false, 'Draft saved automatically.');
    } catch (_) {
      _setAutoSaveState(false, 'Autosave failed. You can still save manually.');
    }
  }

  Future<void> _uploadStepDocument(
    dynamic controller,
    String documentType,
  ) async {
    final file = await pickPrescriptionFile();
    if (file == null || _draftCustomerId == null) {
      return;
    }
    await controller.uploadCustomerDocument(
      customerId: _draftCustomerId!,
      fileName: file.name,
      documentType: documentType,
      fileBytes: file.bytes,
      mimeType: file.mimeType ?? 'application/octet-stream',
      fileSize: file.size,
    );
    if (!mounted) {
      return;
    }
    setState(() => _uploadedDocumentCount += 1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document uploaded successfully.')),
    );
  }

  Future<void> _saveRegistration(
    dynamic controller, {
    required bool submit,
    required bool showFeedback,
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
      if (selectedId != null && selectedId.isNotEmpty && mounted) {
        setState(() => _draftCustomerId = selectedId);
      }
    } else {
      await controller.updateCustomer(
        customerId: _draftCustomerId!,
        payload: payload,
      );
    }

    if (showFeedback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            submit ? 'Registration submitted.' : 'Draft saved successfully.',
          ),
        ),
      );
    }
  }

  void _hydrateDraft(Map<String, dynamic> selected) {
    _firstNameController.text =
        selected['fullName']?.toString().split(' ').firstOrNull ?? '';
    _lastNameController.text =
        selected['fullName']?.toString().split(' ').skip(1).join(' ') ?? '';
    _mobileController.text = selected['mobile']?.toString() ?? '';
    _emailController.text = selected['email']?.toString() ?? '';
    _addressController.text = selected['addressLine1']?.toString() ?? '';
    _currentStep = 0;
    _uploadedDocumentCount = 0;
  }

  void _resetForNewDraft() {
    _firstNameController.clear();
    _lastNameController.clear();
    _mobileController.clear();
    _emailController.clear();
    _aadhaarController.clear();
    _referralController.clear();
    _addressController.clear();
    _uploadedDocumentCount = 0;
    _currentStep = 0;
    _autoSaveMessage = 'Draft autosaves when you move between steps.';
  }

  void _setAutoSaveState(bool saving, String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _autoSaving = saving;
      _autoSaveMessage = message;
    });
    _saveMessageTimer?.cancel();
    if (!saving) {
      _saveMessageTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _autoSaveMessage = 'Draft autosaves when you move between steps.';
        });
      });
    }
  }

  Widget _fieldBox(Widget child) {
    return SizedBox(width: 280, child: child);
  }
}

const _steps = ['Personal', 'Identity', 'Membership', 'Documents', 'Review'];

String _stepSubtitle(int index) {
  switch (index) {
    case 0:
      return 'Capture the customer details the agent already knows.';
    case 1:
      return 'Separate generated SHIELD ID from manual government identity.';
    case 2:
      return 'Choose membership and branch before moving to documents.';
    case 3:
      return 'Upload required files once the draft exists.';
    default:
      return 'Review everything once before you submit the registration.';
  }
}

class _RegistrationStepScaffold extends StatelessWidget {
  const _RegistrationStepScaffold({
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String title;
  final String subtitle;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.only(bottom: 4), child: body),
      ],
    );
  }
}

class _StepContentCard extends StatelessWidget {
  const _StepContentCard({
    required this.title,
    required this.summary,
    required this.child,
  });

  final String title;
  final String summary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AgentPanelCard(title: title, subtitle: summary, child: child);
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label, required this.state});

  final String label;
  final _StepChipState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepChipState.complete => AgentColors.success,
      _StepChipState.active => Theme.of(context).colorScheme.primary,
      _StepChipState.inactive => Theme.of(context).colorScheme.outline,
    };
    final icon = switch (state) {
      _StepChipState.complete => Icons.check_circle,
      _StepChipState.active => Icons.radio_button_checked,
      _StepChipState.inactive => Icons.radio_button_unchecked,
    };
    return AgentStatusBadge(label: label, color: color, icon: icon);
  }
}

enum _StepChipState { complete, active, inactive }

class _RequiredDocumentRow extends StatelessWidget {
  const _RequiredDocumentRow({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? AgentColors.success : AgentColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
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
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

extension _FirstOrNull on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}

extension on String {
  String ifBlank(String fallback) => trim().isEmpty ? fallback : this;
}
