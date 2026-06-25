import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/document.dart';
import '../../../../shared/models/shield_role.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/portal_support.dart';
import '../../../../shared/services/api_service.dart';
import 'package:go_router/go_router.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<Document>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    setState(() {
      _documentsFuture = ApiService.getDocuments(SHIELDRole.customer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showPortalSnackBar(
                context,
                'Document upload is supported in the customer documents and role-based review screens.',
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Document>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppCustomerSectionSkeleton(
              showHero: false,
              showActionRow: true,
              statCards: 0,
              listItems: 6,
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text('Failed to load documents', style: AppTypography.h3),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 16),
                    AppButton(text: 'Retry', onPressed: _loadDocuments),
                  ],
                ),
              ),
            );
          }

          final documents = snapshot.data ?? [];

          if (documents.isEmpty) {
            return PortalEmptyState(
              icon: Icons.description_outlined,
              title: 'No documents yet',
              description:
                  'Uploaded prescriptions, reports, and invoices will appear here once the customer starts using SHIELD services.',
              actionText: 'Open Documents',
              onAction: () => context.go('/portal/customer/documents'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadDocuments(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final document = documents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () {
                      showPortalDetailsSheet(
                        context,
                        title: document.fileName,
                        subtitle:
                            'This ${_getStatusText(document.status).toLowerCase()} file is shown in the customer archive with document-intelligence status visible.',
                        meta:
                            '${document.uploadedAt.day}/${document.uploadedAt.month}/${document.uploadedAt.year}',
                        status: _getStatusText(document.status),
                        highlights: [
                          'Document type: ${document.type?.name ?? 'Other'}',
                          'Uploaded by: ${document.uploadedBy ?? 'System'}',
                          if (document.processedAt != null)
                            'Processed on ${document.processedAt!.day}/${document.processedAt!.month}/${document.processedAt!.year}.',
                        ],
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getTypeColor(
                              document.type,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTypeIcon(document.type),
                            color: _getTypeColor(document.type),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.fileName,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${document.uploadedAt.day}/${document.uploadedAt.month}/${document.uploadedAt.year}',
                                style: AppTypography.tiny.copyWith(
                                  color: AppColors.gray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              document.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getStatusText(document.status),
                            style: AppTypography.tiny.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(document.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getTypeIcon(DocumentType? type) {
    switch (type) {
      case DocumentType.prescription:
        return Icons.medication;
      case DocumentType.labReport:
        return Icons.science;
      case DocumentType.dentalRecord:
        return Icons.medical_services;
      case DocumentType.invoice:
        return Icons.receipt;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(DocumentType? type) {
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

  Color _getStatusColor(DocumentStatus status) {
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

  String _getStatusText(DocumentStatus status) {
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
