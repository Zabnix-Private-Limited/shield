import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_typography.dart';
import '../../../../../../shared/utils/prescription_file_picker.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _qualificationsController =
      TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _registrationAuthorityController =
      TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _workingHoursController = TextEditingController();

  String? _primaryBranchId;
  String? _departmentId;
  Set<String> _assignedBranchIds = <String>{};
  String? _profileVersion;

  @override
  void dispose() {
    _displayNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _qualificationsController.dispose();
    _specializationController.dispose();
    _registrationNumberController.dispose();
    _registrationAuthorityController.dispose();
    _licenseNumberController.dispose();
    _availabilityController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  void _hydrateProfile(Map<String, dynamic> profile) {
    final version =
        profile['updatedAt']?.toString() ??
        profile['profileId']?.toString() ??
        'provider-profile';
    if (_profileVersion == version) {
      return;
    }

    final contact =
        profile['contact'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final registration =
        profile['registration'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final availability =
        profile['consultationAvailability'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final workingHours =
        profile['workingHours'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final assignedBranches =
        (profile['assignedBranches'] as List? ?? const <dynamic>[])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
    final department =
        profile['department'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final primaryBranch =
        profile['primaryBranch'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    _displayNameController.text = profile['displayName']?.toString() ?? '';
    _contactEmailController.text = contact['email']?.toString() ?? '';
    _contactPhoneController.text = contact['phone']?.toString() ?? '';
    _qualificationsController.text = profile['qualifications']?.toString() ?? '';
    _specializationController.text = profile['specialization']?.toString() ?? '';
    _registrationNumberController.text =
        registration['number']?.toString() ?? '';
    _registrationAuthorityController.text =
        registration['authority']?.toString() ?? '';
    _licenseNumberController.text =
        registration['licenseNumber']?.toString() ?? '';
    _availabilityController.text = availability['summary']?.toString() ?? '';
    _workingHoursController.text = workingHours['summary']?.toString() ?? '';
    _assignedBranchIds = assignedBranches
        .map((branch) => branch['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    _primaryBranchId = primaryBranch['id']?.toString();
    _departmentId = department['id']?.toString();
    _profileVersion = version;
  }

  Future<void> _saveProfile(
    BuildContext context,
    dynamic controller,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final payload = <String, dynamic>{
      'displayName': _displayNameController.text.trim(),
      'contact': {
        'email': _contactEmailController.text.trim(),
        'phone': _contactPhoneController.text.trim(),
      },
      'qualifications': _qualificationsController.text.trim(),
      'specialization': _specializationController.text.trim(),
      'registration': {
        'number': _registrationNumberController.text.trim(),
        'authority': _registrationAuthorityController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
      },
      'consultationAvailability': {
        'summary': _availabilityController.text.trim(),
      },
      'workingHours': {
        'summary': _workingHoursController.text.trim(),
      },
      'primaryBranchId': _primaryBranchId,
      'departmentId': _departmentId,
      'assignedBranchIds': _assignedBranchIds.toList(),
    };

    try {
      await controller.saveProviderProfile(payload);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(controller.error?.toString() ?? 'Unable to update profile.'),
        ),
      );
    }
  }

  Future<void> _pickAndUploadAsset(
    BuildContext context,
    dynamic controller, {
    required bool isPhoto,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await pickPrescriptionFile();
    if (file == null) {
      return;
    }
    final mimeType = (file.mimeType ?? '').toLowerCase();
    if (!mimeType.startsWith('image/')) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isPhoto
                ? 'Choose a PNG, JPG, or WEBP image for the profile photo.'
                : 'Choose a PNG, JPG, or WEBP image for the digital signature.',
          ),
        ),
      );
      return;
    }

    try {
      if (isPhoto) {
        await controller.uploadProviderProfilePhoto(
          fileName: file.name,
          fileBytes: file.bytes,
          mimeType: mimeType,
          fileSize: file.size,
        );
      } else {
        await controller.uploadProviderSignature(
          fileName: file.name,
          fileBytes: file.bytes,
          mimeType: mimeType,
          fileSize: file.size,
        );
      }
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isPhoto ? 'Profile photo updated.' : 'Digital signature updated.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            controller.error?.toString() ?? 'Unable to upload the selected file.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final profile = controller.providerProfile;
        final lookups =
            profile['lookups'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final branches =
            (lookups['branches'] as List? ?? const <dynamic>[])
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
        final departments =
            (lookups['departments'] as List? ?? const <dynamic>[])
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
        final assets =
            profile['assets'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final profilePhoto =
            assets['profilePhoto'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final digitalSignature =
            assets['digitalSignature'] as Map<String, dynamic>? ??
            const <String, dynamic>{};

        _hydrateProfile(profile);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My profile', style: AppTypography.h4),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _AssetCard(
                            title: 'Profile photo',
                            fileName: profilePhoto['fileName']?.toString(),
                            imageUrl: profilePhoto['url']?.toString(),
                            actionLabel: 'Upload photo',
                            enabled: !controller.isProviderProfileSaving,
                            onPressed: () => _pickAndUploadAsset(
                              context,
                              controller,
                              isPhoto: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AssetCard(
                            title: 'Digital signature',
                            fileName: digitalSignature['fileName']?.toString(),
                            imageUrl: digitalSignature['url']?.toString(),
                            actionLabel: 'Upload signature',
                            enabled: !controller.isProviderProfileSaving,
                            onPressed: () => _pickAndUploadAsset(
                              context,
                              controller,
                              isPhoto: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Professional email',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _contactPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Professional phone',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _qualificationsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Qualifications',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _specializationController,
                      decoration: const InputDecoration(
                        labelText: 'Specialization',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _registrationNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Registration number',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _licenseNumberController,
                            decoration: const InputDecoration(
                              labelText: 'License number',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _registrationAuthorityController,
                      decoration: const InputDecoration(
                        labelText: 'Registration authority',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Assigned branches', style: AppTypography.h5),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: branches.map((branch) {
                        final branchId = branch['id']?.toString() ?? '';
                        final isSelected = _assignedBranchIds.contains(branchId);
                        return FilterChip(
                          label: Text(branch['name']?.toString() ?? 'Branch'),
                          selected: isSelected,
                          onSelected: controller.isProviderProfileSaving
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _assignedBranchIds.add(branchId);
                                      _primaryBranchId ??= branchId;
                                    } else {
                                      _assignedBranchIds.remove(branchId);
                                      if (_primaryBranchId == branchId) {
                                        _primaryBranchId = _assignedBranchIds
                                            .isEmpty
                                            ? null
                                            : _assignedBranchIds.first;
                                      }
                                    }
                                  });
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _primaryBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Primary branch',
                      ),
                      items: branches
                          .where(
                            (branch) => _assignedBranchIds.contains(
                              branch['id']?.toString() ?? '',
                            ),
                          )
                          .map(
                            (branch) => DropdownMenuItem<String>(
                              value: branch['id']?.toString(),
                              child: Text(branch['name']?.toString() ?? 'Branch'),
                            ),
                          )
                          .toList(),
                      onChanged: controller.isProviderProfileSaving
                          ? null
                          : (value) => setState(() => _primaryBranchId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _departmentId,
                      decoration: const InputDecoration(labelText: 'Department'),
                      items: departments
                          .where((department) {
                            if (_assignedBranchIds.isEmpty) {
                              return true;
                            }
                            return _assignedBranchIds.contains(
                              department['businessId']?.toString() ?? '',
                            );
                          })
                          .map(
                            (department) => DropdownMenuItem<String>(
                              value: department['id']?.toString(),
                              child: Text(
                                department['name']?.toString() ?? 'Department',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: controller.isProviderProfileSaving
                          ? null
                          : (value) => setState(() => _departmentId = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _availabilityController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Consultation availability',
                        hintText:
                            'Example: Available for clinic and teleconsultation on weekdays.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _workingHoursController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Working hours',
                        hintText:
                            'Example: Monday to Saturday, 09:00 AM to 05:00 PM.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: controller.isProviderProfileSaving
                            ? null
                            : () => _saveProfile(context, controller),
                        child: Text(
                          controller.isProviderProfileSaving
                              ? 'Saving...'
                              : 'Save profile',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.title,
    required this.fileName,
    required this.imageUrl,
    required this.actionLabel,
    required this.enabled,
    required this.onPressed,
  });

  final String title;
  final String? fileName;
  final String? imageUrl;
  final String actionLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.h5),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text('Preview unavailable')),
                        ),
                      )
                    : const Center(child: Text('No file uploaded')),
              ),
            ),
            const SizedBox(height: 8),
            Text(fileName?.trim().isNotEmpty == true ? fileName! : 'No file selected'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: enabled ? onPressed : null,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
