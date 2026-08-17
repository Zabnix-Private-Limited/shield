import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
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
  final _alternativeMobileController = TextEditingController();
  final _alternativeContactNameController = TextEditingController();
  final _alternativeRelationshipController = TextEditingController();
  final _emailController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _referralController = TextEditingController();
  final _addressController = TextEditingController();

  String _gender = 'MALE';
  String? _membershipTypeCode;
  String? _draftCustomerId;
  String? _selectedBusinessId;
  Map<String, dynamic>? _existingCustomer;
  bool _existingLookupLoading = false;
  bool _convertingExistingCustomer = false;
  bool _prescriptionSkipped = false;
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
    _alternativeMobileController.dispose();
    _alternativeContactNameController.dispose();
    _alternativeRelationshipController.dispose();
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
    final rawMembershipTypes = controller.membershipTypes;
    final rawBusinesses = controller.businesses;

    final effectiveMembershipTypes = rawMembershipTypes.isNotEmpty
        ? rawMembershipTypes
        : const [
            {'code': 'STANDARD', 'name': 'Standard Membership'},
            {'code': 'FOUNDING', 'name': 'Founding Member'},
          ];

    final effectiveBusinesses = rawBusinesses.isNotEmpty
        ? rawBusinesses
        : const [
            {'id': '1', 'name': 'Sahakar Healthcare Group (Main)'},
            {'id': '2', 'name': 'Hyperpharmacy Branch 1'},
          ];

    final validMembershipCodes = effectiveMembershipTypes
        .map((item) => (item['code'] ?? item['id'])?.toString())
        .whereType<String>()
        .where((code) => code.trim().isNotEmpty)
        .toList();

    if (_membershipTypeCode == null ||
        !validMembershipCodes.contains(_membershipTypeCode)) {
      _membershipTypeCode = validMembershipCodes.firstOrNull;
    }

    final validBusinessIds = effectiveBusinesses
        .map((item) => (item['id'] ?? item['code'])?.toString())
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toList();

    if (_selectedBusinessId == null ||
        !validBusinessIds.contains(_selectedBusinessId)) {
      _selectedBusinessId = validBusinessIds.firstOrNull;
    }

    final drafts = controller.customers
        .where(
          (customer) => [
            'PENDING',
            'INCOMPLETE',
            'REJECTED',
          ].contains((customer['status'] ?? '').toString().toUpperCase()),
        )
        .toList();

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
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Resume saved draft',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Start a new registration',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...drafts.map(
                  (draft) => DropdownMenuItem<String>(
                    value: draft['id']?.toString(),
                    child: Text(
                      '${draft['fullName'] ?? 'Customer'} • ${draft['mobile'] ?? ''} • ${_humanize(draft['status'])}',
                      overflow: TextOverflow.ellipsis,
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
                    effectiveMembershipTypes,
                    effectiveBusinesses,
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
              const SizedBox(width: 10),
              AgentSecondaryButton(
                onPressed: _autoSaving
                    ? null
                    : () => _manualSaveDraft(controller),
                icon: const Icon(Icons.bookmark_outline, size: 18),
                label: _autoSaving ? 'Saving...' : 'Save Draft',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _fieldBox(
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          label: _buildRequiredLabel('First name'),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter first name'
                            : null,
                      ),
                    ),
                    _fieldBox(
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                        ),
                      ),
                    ),
                    _fieldBox(
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          label: _buildRequiredLabel('Phone'),
                        ),
                        onChanged: (_) =>
                            setState(() => _existingCustomer = null),
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
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'MALE',
                            child: Text('Male', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'FEMALE',
                            child: Text('Female', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'OTHER',
                            child: Text('Other', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _gender = value ?? 'MALE'),
                        decoration: InputDecoration(
                          label: _buildRequiredLabel('Gender'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AgentSecondaryButton(
                  onPressed: _existingLookupLoading
                      ? null
                      : () => _lookupExistingCustomer(controller),
                  icon: const Icon(Icons.person_search_outlined),
                  label: _existingLookupLoading
                      ? 'Searching existing customers...'
                      : 'Check existing customer',
                ),
                if (_existingCustomer != null) ...[
                  const SizedBox(height: 16),
                  _ExistingCustomerResult(
                    customer: _existingCustomer!,
                    isConverting: _convertingExistingCustomer,
                    onConvert: () => _convertExistingCustomer(controller),
                  ),
                ],
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
                    style: AppTypography.body.copyWith(color: AppColors.darkGray),
                    decoration: InputDecoration(
                      labelText: 'SHIELD customer ID',
                      hintText: 'Generated automatically after registration',
                      filled: true,
                      fillColor: AppColors.lightGray,
                    ),
                  ),
                ),
                _fieldBox(
                  TextFormField(
                    controller: _alternativeMobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Alternative mobile (optional)',
                      helperText: 'Never used for login or OTP',
                    ),
                  ),
                ),
                _fieldBox(
                  TextFormField(
                    controller: _alternativeContactNameController,
                    decoration: const InputDecoration(
                      labelText: 'Alternative contact name',
                    ),
                  ),
                ),
                _fieldBox(
                  TextFormField(
                    controller: _alternativeRelationshipController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship to customer',
                    ),
                  ),
                ),
                _fieldBox(
                  TextFormField(
                    controller: _aadhaarController,
                    decoration: InputDecoration(
                      label: _buildRequiredLabel('Aadhaar / Government ID'),
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
                    style: AppTypography.body.copyWith(color: AppColors.darkGray),
                    decoration: InputDecoration(
                      labelText: 'Assigned agent',
                      filled: true,
                      fillColor: AppColors.lightGray,
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
                        key: ValueKey('membership_type_$_membershipTypeCode'),
                        initialValue: _membershipTypeCode,
                        isExpanded: true,
                        items: membershipTypes
                            .map((item) {
                              final code = (item['code'] ?? item['id'])?.toString() ?? 'STANDARD';
                              final name = item['name']?.toString() ?? code;
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text(name, overflow: TextOverflow.ellipsis),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _membershipTypeCode = value);
                          }
                        },
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Choose membership plan'
                            : null,
                        decoration: InputDecoration(
                          label: _buildRequiredLabel('Membership plan'),
                        ),
                      ),
                    ),
                    _fieldBox(
                      DropdownButtonFormField<String>(
                        key: ValueKey('business_id_$_selectedBusinessId'),
                        initialValue: _selectedBusinessId,
                        isExpanded: true,
                        items: businesses
                            .map((item) {
                              final id = (item['id'] ?? item['code'])?.toString() ?? '1';
                              final name = item['name']?.toString() ?? 'Branch $id';
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(name, overflow: TextOverflow.ellipsis),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedBusinessId = value);
                          }
                        },
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Choose branch'
                            : null,
                        decoration: InputDecoration(
                          label: _buildRequiredLabel('Preferred branch'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          label: _buildRequiredLabel('Address'),
                        ),
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
                    AgentSecondaryButton(
                      onPressed: _draftCustomerId == null
                          ? null
                          : () =>
                                _uploadStepDocument(controller, 'PRESCRIPTION'),
                      icon: const Icon(Icons.medical_services_outlined),
                      label: 'Upload Prescription',
                    ),
                    AgentSecondaryButton(
                      onPressed: () =>
                          setState(() => _prescriptionSkipped = true),
                      label: _prescriptionSkipped
                          ? 'Prescription skipped'
                          : 'Skip for Now',
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
        final missingRequirements = _getMissingRequirements();
        final isFirstNameMissing = _firstNameController.text.trim().isEmpty;
        final isMobileMissing = _mobileController.text.trim().length < 10;
        final isGovernmentIdMissing = _aadhaarController.text.trim().isEmpty;
        final isPlanMissing = (_membershipTypeCode ?? '').trim().isEmpty;
        final isBranchMissing = (_selectedBusinessId ?? '').trim().isEmpty;
        final isAddressMissing = _addressController.text.trim().isEmpty;

        return _StepContentCard(
          title: 'Review and Submit',
          summary:
              'Check the customer summary once before sending it for approval. Required missing fields are highlighted.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (missingRequirements.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Missing Required Fields',
                              style: AppTypography.small.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Please complete: ${missingRequirements.map((m) => m.fieldName).join(', ')}',
                              style: AppTypography.small.copyWith(color: AppColors.darkGray),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(
                          () => _currentStep = missingRequirements.first.step,
                        ),
                        child: const Text(
                          'Fix Now',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _ReviewItem(
                label: 'Customer',
                value: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
                required: true,
                missing: isFirstNameMissing,
              ),
              _ReviewItem(
                label: 'Phone',
                value: _mobileController.text.trim(),
                required: true,
                missing: isMobileMissing,
              ),
              _ReviewItem(
                label: 'Email',
                value: _emailController.text.trim().ifBlank('Not set'),
              ),
              _ReviewItem(
                label: 'Government ID',
                value: _aadhaarController.text.trim(),
                required: true,
                missing: isGovernmentIdMissing,
              ),
              _ReviewItem(
                label: 'Membership plan',
                value: _membershipTypeCode ?? '',
                required: true,
                missing: isPlanMissing,
              ),
              _ReviewItem(
                label: 'Preferred branch',
                value: _selectedBusinessId ?? '',
                required: true,
                missing: isBranchMissing,
              ),
              _ReviewItem(
                label: 'Address',
                value: _addressController.text.trim(),
                required: true,
                missing: isAddressMissing,
              ),
              _ReviewItem(
                label: 'Documents uploaded',
                value: '$_uploadedDocumentCount',
              ),
              const SizedBox(height: 16),
              AgentStatusBadge(
                label: missingRequirements.isNotEmpty
                    ? 'Incomplete registration - Fix missing fields'
                    : (_draftCustomerId == null
                        ? 'New registration'
                        : 'Saved draft ready to submit'),
                color: missingRequirements.isNotEmpty
                    ? AgentColors.danger
                    : (_draftCustomerId == null
                        ? AgentColors.warning
                        : AgentColors.success),
                icon: missingRequirements.isNotEmpty
                    ? Icons.error_outline
                    : (_draftCustomerId == null
                        ? Icons.edit_note_outlined
                        : Icons.check_circle_outline),
              ),
            ],
          ),
        );
    }
  }

  Future<void> _lookupExistingCustomer(dynamic controller) async {
    final mobile = _mobileController.text.trim();
    if (mobile.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a complete mobile number first.')),
      );
      return;
    }
    setState(() => _existingLookupLoading = true);
    try {
      final customer = await controller.findExistingCustomerByMobile(mobile);
      if (!mounted) return;
      setState(() => _existingCustomer = customer);
      if (customer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No existing customer found. Continue registration.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _existingLookupLoading = false);
    }
  }

  Future<void> _convertExistingCustomer(dynamic controller) async {
    final customerId = _existingCustomer?['id']?.toString();
    if (customerId == null || customerId.isEmpty) return;
    if (_existingCustomer?['membership'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Membership already exists. Open the customer profile.',
          ),
        ),
      );
      return;
    }
    setState(() => _convertingExistingCustomer = true);
    try {
      await controller.convertExistingCustomerToMembership(
        customerId: customerId,
        membershipTypeCode: _membershipTypeCode,
      );
      if (!mounted) return;
      setState(() => _draftCustomerId = customerId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SHIELD membership linked to existing customer.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _convertingExistingCustomer = false);
    }
  }

  List<_MissingRequirement> _getMissingRequirements() {
    final missing = <_MissingRequirement>[];

    if (_firstNameController.text.trim().isEmpty) {
      missing.add(const _MissingRequirement(step: 0, fieldName: 'First name *'));
    }
    if (_mobileController.text.trim().length < 10) {
      missing.add(const _MissingRequirement(step: 0, fieldName: 'Phone number *'));
    }
    if (_gender.trim().isEmpty) {
      missing.add(const _MissingRequirement(step: 0, fieldName: 'Gender *'));
    }
    if (_aadhaarController.text.trim().isEmpty) {
      missing.add(const _MissingRequirement(step: 1, fieldName: 'Aadhaar / Government ID *'));
    }
    if ((_membershipTypeCode ?? '').trim().isEmpty) {
      missing.add(const _MissingRequirement(step: 2, fieldName: 'Membership plan *'));
    }
    if ((_selectedBusinessId ?? '').trim().isEmpty) {
      missing.add(const _MissingRequirement(step: 2, fieldName: 'Preferred branch *'));
    }
    if (_addressController.text.trim().isEmpty) {
      missing.add(const _MissingRequirement(step: 2, fieldName: 'Address *'));
    }

    return missing;
  }

  Future<bool> _goToNextStep(dynamic controller) async {
    if (!_validateCurrentStep(showFeedback: true)) {
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
    final missingRequirements = _getMissingRequirements();
    if (missingRequirements.isNotEmpty) {
      final firstMissing = missingRequirements.first;
      final missingNames = missingRequirements.map((m) => m.fieldName).join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          content: Text(
            'Cannot submit registration. Missing required fields: $missingNames',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          action: SnackBarAction(
            label: 'FIX NOW',
            textColor: Colors.white,
            onPressed: () => setState(() => _currentStep = firstMissing.step),
          ),
        ),
      );

      setState(() => _currentStep = firstMissing.step);
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

  bool _validateCurrentStep({bool showFeedback = false}) {
    bool valid = true;
    final missingInCurrentStep = <String>[];

    switch (_currentStep) {
      case 0:
        valid = _detailsFormKey.currentState?.validate() ?? false;
        if (_firstNameController.text.trim().isEmpty) missingInCurrentStep.add('First name *');
        if (_mobileController.text.trim().length < 10) missingInCurrentStep.add('Phone *');
        if (_gender.trim().isEmpty) missingInCurrentStep.add('Gender *');
        break;
      case 1:
        valid = _identityFormKey.currentState?.validate() ?? false;
        if (_aadhaarController.text.trim().isEmpty) missingInCurrentStep.add('Aadhaar / Government ID *');
        break;
      case 2:
        valid = _membershipFormKey.currentState?.validate() ?? false;
        if ((_membershipTypeCode ?? '').trim().isEmpty) missingInCurrentStep.add('Membership plan *');
        if ((_selectedBusinessId ?? '').trim().isEmpty) missingInCurrentStep.add('Preferred branch *');
        if (_addressController.text.trim().isEmpty) missingInCurrentStep.add('Address *');
        break;
      default:
        valid = true;
    }

    if (!valid && showFeedback && missingInCurrentStep.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Cannot proceed. Please complete required fields: ${missingInCurrentStep.join(', ')}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return valid;
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
    if (documentType == 'PRESCRIPTION') {
      setState(() => _prescriptionSkipped = false);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document uploaded successfully.')),
    );
  }

  Future<void> _manualSaveDraft(dynamic controller) async {
    _setAutoSaveState(true, 'Saving draft...');
    try {
      await _saveRegistration(controller, submit: false, showFeedback: true);
      _setAutoSaveState(false, 'Draft saved successfully.');
    } catch (_) {
      _setAutoSaveState(false, 'Save draft failed. Please check network connection.');
    }
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
      'issued_business_id': _selectedBusinessId,
      'business_id': _selectedBusinessId,
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

    final alternativeMobile = _alternativeMobileController.text.trim();
    if (alternativeMobile.isNotEmpty && _draftCustomerId != null) {
      await controller.saveAlternativeCustomerContact(
        customerId: _draftCustomerId!,
        payload: {
          'mobile': alternativeMobile,
          'name': _alternativeContactNameController.text.trim(),
          'relationship': _alternativeRelationshipController.text.trim(),
        },
      );
    }

    if (showFeedback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            submit ? 'Registration submitted successfully.' : 'Draft saved successfully.',
          ),
        ),
      );
    }
  }

  void _hydrateDraft(Map<String, dynamic> selected) {
    setState(() {
      final customerId = selected['id']?.toString();
      if (customerId != null && customerId.isNotEmpty) {
        _draftCustomerId = customerId;
      }

      final fullName = selected['fullName']?.toString() ?? selected['first_name']?.toString() ?? '';
      _firstNameController.text = selected['firstName']?.toString() ??
          selected['first_name']?.toString() ??
          (fullName.split(' ').firstOrNull ?? '');
      _lastNameController.text = selected['lastName']?.toString() ??
          selected['last_name']?.toString() ??
          (fullName.split(' ').skip(1).join(' '));
      _mobileController.text = selected['mobile']?.toString() ?? '';
      _emailController.text = selected['email']?.toString() ?? '';
      _aadhaarController.text = selected['aadhaarNumber']?.toString() ??
          selected['aadhaar_number']?.toString() ??
          '';
      _addressController.text = selected['addressLine1']?.toString() ??
          selected['address_line1']?.toString() ??
          '';
      _referralController.text = selected['referredByCode']?.toString() ??
          selected['referred_by_code']?.toString() ??
          '';

      final genderVal = (selected['gender']?.toString() ?? 'MALE').toUpperCase();
      if (['MALE', 'FEMALE', 'OTHER'].contains(genderVal)) {
        _gender = genderVal;
      }

      final memType = selected['membershipTypeCode']?.toString() ??
          selected['membership_type_code']?.toString();
      if (memType != null && memType.isNotEmpty) {
        _membershipTypeCode = memType;
      }

      final busId = selected['issuedBusinessId']?.toString() ??
          selected['business_id']?.toString() ??
          selected['issued_business_id']?.toString();
      if (busId != null && busId.isNotEmpty) {
        _selectedBusinessId = busId;
      }

      final contacts = selected['customerContacts'];
      if (contacts is List && contacts.isNotEmpty) {
        final firstContact = contacts.first;
        if (firstContact is Map) {
          _alternativeMobileController.text =
              firstContact['mobile']?.toString() ?? '';
          _alternativeContactNameController.text =
              firstContact['name']?.toString() ?? '';
          _alternativeRelationshipController.text =
              firstContact['relationship']?.toString() ?? '';
        }
      }

      final docs = selected['documents'];
      if (docs is List) {
        _uploadedDocumentCount = docs.length;
      } else {
        _uploadedDocumentCount = 0;
      }

      _currentStep = 0;
      _autoSaveMessage = 'Draft restored. Changes autosave when navigating steps.';
    });
  }

  void _resetForNewDraft() {
    _firstNameController.clear();
    _lastNameController.clear();
    _mobileController.clear();
    _alternativeMobileController.clear();
    _alternativeContactNameController.clear();
    _alternativeRelationshipController.clear();
    _emailController.clear();
    _aadhaarController.clear();
    _referralController.clear();
    _addressController.clear();
    _uploadedDocumentCount = 0;
    _currentStep = 0;
    _existingCustomer = null;
    _prescriptionSkipped = false;
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
    return SizedBox(width: 320, child: child);
  }

  Widget _buildRequiredLabel(String text) {
    return Text.rich(
      TextSpan(
        text: text,
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

const _steps = ['Personal', 'Identity', 'Membership', 'Documents', 'Review'];

class _ExistingCustomerResult extends StatelessWidget {
  const _ExistingCustomerResult({
    required this.customer,
    required this.isConverting,
    required this.onConvert,
  });

  final Map<String, dynamic> customer;
  final bool isConverting;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    final membership = customer['membership'];
    final hasMembership = membership is Map;
    final name = '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'
        .trim();
    return AgentPanelCard(
      title: hasMembership
          ? 'Membership Already Exists'
          : 'Existing Customer Found',
      subtitle: hasMembership
          ? 'Do not register this mobile number again.'
          : 'Link a SHIELD membership to this existing customer.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewItem(
            label: 'Existing customer ID',
            value:
                customer['customerCode']?.toString() ??
                customer['id']?.toString() ??
                'Unknown',
          ),
          _ReviewItem(
            label: 'Name',
            value: name.isEmpty ? 'Not recorded' : name,
          ),
          _ReviewItem(
            label: 'Mobile number',
            value: customer['mobile']?.toString() ?? 'Not recorded',
          ),
          _ReviewItem(
            label: 'Existing branch/business',
            value:
                customer['existingBusiness']?['name']?.toString() ??
                'Not recorded',
          ),
          const SizedBox(height: 12),
          hasMembership
              ? AgentSecondaryButton(
                  onPressed: () => context.go('/portal/agent/customers'),
                  label: 'View customer/member profile',
                )
              : AgentPrimaryButton(
                  onPressed: isConverting ? null : onConvert,
                  label: isConverting
                      ? 'Creating membership...'
                      : 'Create SHIELD Membership',
                ),
        ],
      ),
    );
  }
}

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
  const _ReviewItem({
    required this.label,
    required this.value,
    this.required = false,
    this.missing = false,
  });

  final String label;
  final String value;
  final bool required;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text.rich(
              TextSpan(
                text: label,
                style: Theme.of(context).textTheme.bodySmall,
                children: required
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    : const [],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: missing
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Required * (Missing)',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(value.trim().isEmpty ? 'Not set' : value),
          ),
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

class _MissingRequirement {
  const _MissingRequirement({required this.step, required this.fieldName});
  final int step;
  final String fieldName;
}
