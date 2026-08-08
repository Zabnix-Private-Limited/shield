import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/document.dart';
import '../../../../../shared/services/platform_file_actions.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_skeleton.dart';
import '../../../../../shared/widgets/portal_support.dart';
import '../../../shared/widgets/error_card.dart';
import '../customer_prescriptions_controller.dart';

class CustomerPrescriptionsScreen extends StatefulWidget {
  const CustomerPrescriptionsScreen({super.key, this.controller});

  final CustomerPrescriptionsController? controller;

  @override
  State<CustomerPrescriptionsScreen> createState() =>
      _CustomerPrescriptionsScreenState();
}

class _CustomerPrescriptionsScreenState
    extends State<CustomerPrescriptionsScreen> {
  late final CustomerPrescriptionsController _controller;
  late final bool _ownsController;
  late Future<List<Document>> _prescriptionsFuture;
  String? _pharmacyProviderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _pharmacyProviderId = GoRouterState.of(
        context,
      ).uri.queryParameters['provider'];
    } catch (_) {
      _pharmacyProviderId = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CustomerPrescriptionsController();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _loadPrescriptions() {
    setState(() {
      _prescriptionsFuture = _controller.load().then((_) {
        if (_controller.error != null) throw _controller.error!;
        return _controller.prescriptions;
      });
    });
  }

  Future<void> _openPrescription(Document prescription) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await _controller.viewerUrl(prescription);
      if (url.trim().isEmpty || !await openPlatformUrl(url)) {
        throw StateError('Prescription link unavailable');
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('We could not open that prescription right now.'),
          ),
        );
      }
    }
  }

  Future<void> _downloadPrescription(Document prescription) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await _controller.viewerUrl(prescription);
      if (url.trim().isEmpty ||
          !await downloadPlatformUrl(url, fileName: prescription.fileName)) {
        throw StateError('Prescription link unavailable');
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('We could not download that prescription right now.'),
          ),
        );
      }
    }
  }

  Future<void> _reviewAndSubmit(Document prescription) async {
    final preferred = _controller.preferredPharmacy;
    final providerId = _pharmacyProviderId ?? preferred?['id']?.toString();
    if (providerId == null || providerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select a pharmacy from Services first.'),
          ),
        );
      }
      return;
    }
    final notes = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send prescription to pharmacy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prescription: ${prescription.fileName}'),
            const SizedBox(height: 8),
            Text(
              _pharmacyProviderId != null
                  ? 'Selected pharmacy from Services'
                  : 'Your preferred pharmacy: ${preferred?['providerName'] ?? preferred?['name'] ?? 'selected pharmacy'}',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notes,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Optional note',
                hintText: 'Add a note for the pharmacy',
              ),
            ),
            const Text(
              'By confirming, you allow this pharmacy to access this prescription for review.',
              style: AppTypography.small,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    final note = notes.text;
    notes.dispose();
    if (confirmed != true) return;
    final success = await _controller.submitToPharmacy(
      prescription: prescription,
      providerId: providerId,
      customerNotes: note,
    );
    if (!mounted) return;
    final request = _controller.submittedRequest;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Prescription request ${request?['id'] ?? ''} submitted.'
              : 'Prescription request could not be submitted. Please retry.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Document>>(
      future: _prescriptionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 2,
            listItems: 4,
          );
        }

        if (snapshot.hasError) {
          return ErrorCard(
            title: 'Prescriptions unavailable',
            message: 'Your prescription history could not be loaded.',
            onRetry: () => setState(_loadPrescriptions),
          );
        }

        final prescriptions = snapshot.data ?? const <Document>[];
        final readyCount = prescriptions
            .where((document) => document.status == DocumentStatus.approved)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF14213D), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${prescriptions.length} prescriptions on file',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploaded prescriptions remain in your private SHIELD archive with their real status.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _PrescriptionChip(
                        label: '$readyCount approved',
                        icon: Icons.verified_outlined,
                      ),
                      _PrescriptionChip(
                        label: '${prescriptions.length - readyCount} in review',
                        icon: Icons.medication_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      Uri(
                        path: '/portal/customer/documents',
                        queryParameters: {
                          'type': 'PRESCRIPTION',
                          if (_pharmacyProviderId != null)
                            'provider': _pharmacyProviderId!,
                        },
                      ).toString(),
                    ),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Upload prescription'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_pharmacyProviderId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: const Text(
                    'A pharmacy was selected from Services. Choose a prescription below, review the request, then confirm before it is shared.',
                    style: AppTypography.small,
                  ),
                ),
              ),
            if (prescriptions.isEmpty)
              AppCard(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No prescriptions yet', style: AppTypography.h4),
                    SizedBox(height: 8),
                    Text(
                      'Once prescriptions are uploaded or issued through SHIELD services, they will appear here for the customer.',
                      style: AppTypography.body,
                    ),
                  ],
                ),
              )
            else ...[
              Text('Prescription history', style: AppTypography.h4),
              const SizedBox(height: 12),
              ...prescriptions.map(
                (prescription) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => showPortalDetailsSheet(
                      context,
                      title: prescription.fileName,
                      subtitle:
                          'This prescription is available in the active customer workflow and linked to pharmacy-side review.',
                      meta: _formatDate(prescription.uploadedAt),
                      status: _statusText(prescription.status),
                      highlights: [
                        'Current state: ${_statusText(prescription.status)}',
                        if (prescription.mimeType != null)
                          'File type: ${prescription.mimeType}',
                      ],
                      actionText: 'Open secure prescription',
                      onAction: () => _openPrescription(prescription),
                      secondaryActionText: 'Download',
                      onSecondaryAction: () =>
                          _downloadPrescription(prescription),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.shieldBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.medication_outlined,
                            color: AppColors.shieldBlue,
                          ),
                        ),
                        if (_pharmacyProviderId != null ||
                            _controller.preferredPharmacy != null)
                          TextButton(
                            onPressed: _controller.isSubmitting
                                ? null
                                : () => _reviewAndSubmit(prescription),
                            child: const Text('Send'),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prescription.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(prescription.uploadedAt),
                                style: AppTypography.tiny.copyWith(
                                  color: AppColors.gray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              prescription.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText(prescription.status),
                            style: AppTypography.tiny.copyWith(
                              color: _statusColor(prescription.status),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';

  Color _statusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return AppColors.shieldGreen;
      case DocumentStatus.validated:
        return AppColors.shieldLightBlue;
      case DocumentStatus.processing:
        return AppColors.warning;
      case DocumentStatus.rejected:
        return AppColors.error;
      default:
        return AppColors.gray;
    }
  }

  String _statusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return 'Approved';
      case DocumentStatus.validated:
        return 'Validated';
      case DocumentStatus.processing:
        return 'Processing';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.uploaded:
        return 'Uploaded';
      case DocumentStatus.classified:
        return 'Classified';
      case DocumentStatus.extracted:
        return 'Extracted';
    }
  }
}

class _PrescriptionChip extends StatelessWidget {
  const _PrescriptionChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
