import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/document.dart';
import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_skeleton.dart';
import '../../../../../shared/widgets/portal_support.dart';

class CustomerDocumentsScreen extends StatefulWidget {
  const CustomerDocumentsScreen({super.key});

  @override
  State<CustomerDocumentsScreen> createState() => _CustomerDocumentsScreenState();
}

class _CustomerDocumentsScreenState extends State<CustomerDocumentsScreen> {
  late Future<List<Document>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    setState(() {
      _documentsFuture = ApiService.getCustomerDocumentsStrict(
        ApiService.requireAuthenticatedCustomerId(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Document>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 2,
            listItems: 5,
          );
        }

        if (snapshot.hasError) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Documents unavailable', style: AppTypography.h4),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
                const SizedBox(height: 16),
                AppButton(text: 'Retry', onPressed: _loadDocuments),
              ],
            ),
          );
        }

        final documents = snapshot.data ?? const <Document>[];
        final approvedCount = documents
            .where((document) => document.status == DocumentStatus.approved)
            .length;
        final processingCount = documents
            .where((document) => document.status == DocumentStatus.processing)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.shieldBlue, AppColors.shieldNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${documents.length} documents in your archive',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prescriptions, reports, and invoices uploaded through SHIELD appear here with their latest processing status.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ArchiveChip(
                        label: '$approvedCount approved',
                        icon: Icons.verified_outlined,
                      ),
                      _ArchiveChip(
                        label: '$processingCount processing',
                        icon: Icons.timelapse_outlined,
                      ),
                      _ArchiveChip(
                        label: 'Backend synced',
                        icon: Icons.cloud_done_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (documents.isEmpty)
              AppCard(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No documents yet', style: AppTypography.h4),
                    SizedBox(height: 8),
                    Text(
                      'Uploaded prescriptions, reports, and invoices will appear here once SHIELD starts receiving them for this customer.',
                      style: AppTypography.body,
                    ),
                  ],
                ),
              )
            else ...[
              Text('Archive', style: AppTypography.h4),
              const SizedBox(height: 12),
              ...documents.map(
                (document) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => showPortalDetailsSheet(
                      context,
                      title: document.fileName,
                      subtitle:
                          'This ${_statusText(document.status).toLowerCase()} file is visible in the active customer archive.',
                      meta:
                          '${document.typeLabel} • ${_formatDate(document.uploadedAt)}',
                      status: _statusText(document.status),
                      highlights: [
                        'Uploaded by: ${document.uploadedBy ?? 'System'}',
                        if (document.processedAt != null)
                          'Processed on ${_formatDate(document.processedAt!)}',
                        if ((document.extractionPreview ?? '').trim().isNotEmpty)
                          'OCR preview: ${document.extractionPreview}',
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _typeColor(document.type).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _typeIcon(document.type),
                            color: _typeColor(document.type),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${document.typeLabel} • ${_formatDate(document.uploadedAt)}',
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
                            color: _statusColor(document.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText(document.status),
                            style: AppTypography.tiny.copyWith(
                              color: _statusColor(document.status),
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

  String _formatDate(DateTime value) => '${value.day}/${value.month}/${value.year}';

  IconData _typeIcon(DocumentType? type) {
    switch (type) {
      case DocumentType.prescription:
        return Icons.medication_outlined;
      case DocumentType.labReport:
        return Icons.science_outlined;
      case DocumentType.dentalRecord:
        return Icons.medical_services_outlined;
      case DocumentType.invoice:
        return Icons.receipt_long_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _typeColor(DocumentType? type) {
    switch (type) {
      case DocumentType.prescription:
        return AppColors.shieldBlue;
      case DocumentType.labReport:
        return AppColors.shieldGreen;
      case DocumentType.dentalRecord:
        return AppColors.warning;
      case DocumentType.invoice:
        return AppColors.shieldNavy;
      default:
        return AppColors.gray;
    }
  }

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

class _ArchiveChip extends StatelessWidget {
  const _ArchiveChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
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
