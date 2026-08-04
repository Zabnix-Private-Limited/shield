import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/document.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_skeleton.dart';
import '../../../../../shared/widgets/portal_support.dart';
import '../../../shared/widgets/error_card.dart';

class CustomerPrescriptionsScreen extends StatefulWidget {
  const CustomerPrescriptionsScreen({super.key});

  @override
  State<CustomerPrescriptionsScreen> createState() =>
      _CustomerPrescriptionsScreenState();
}

class _CustomerPrescriptionsScreenState
    extends State<CustomerPrescriptionsScreen> {
  late Future<List<Document>> _prescriptionsFuture;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  void _loadPrescriptions() {
    setState(() {
      _prescriptionsFuture =
          ApiService.getCustomerDocumentsStrict(
            ApiService.requireAuthenticatedCustomerId(),
          ).then(
            (documents) => documents
              ..retainWhere(
                (document) => document.type == DocumentType.prescription,
              ),
          );
    });
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
                    'Uploaded and provider-linked prescriptions stay visible here with OCR and review status when available.',
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
                ],
              ),
            ),
            const SizedBox(height: 18),
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
                        'Upload source: ${prescription.uploadedBy ?? 'Provider'}',
                        'Current state: ${_statusText(prescription.status)}',
                        if ((prescription.extractionPreview ?? '')
                            .trim()
                            .isNotEmpty)
                          'OCR preview: ${prescription.extractionPreview}',
                      ],
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
