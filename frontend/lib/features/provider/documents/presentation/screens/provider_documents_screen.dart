import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../../../../shared/services/platform_file_actions.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderDocumentsScreen extends StatelessWidget {
  const ProviderDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final roleKey =
            GoRouterState.of(context).pathParameters['role'] ?? 'provider';
        final selectedCustomer = controller.selectedCustomer;
        final prescriptions = controller.selectedPrescriptionDocuments;
        final labReports = controller.selectedLabReportDocuments;
        final invoices = controller.selectedInvoiceDocuments;
        final otherDocuments = controller.selectedOtherDocuments;

        Future<void> openDocument(dynamic document) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            final url = await controller.getPatientDocumentDownloadUrl(
              document.id,
            );
            if (url.trim().isEmpty) {
              throw StateError('Document link unavailable');
            }
            final opened = await openPlatformUrl(url);
            if (!opened) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                    'This device cannot open the document automatically yet.',
                  ),
                ),
              );
            }
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('We could not open that document right now.'),
              ),
            );
          }
        }

        Future<void> downloadDocument(dynamic document) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            final url = await controller.getPatientDocumentDownloadUrl(
              document.id,
            );
            if (url.trim().isEmpty) {
              throw StateError('Document link unavailable');
            }
            final downloaded = await downloadPlatformUrl(
              url,
              fileName: document.fileName,
            );
            if (!downloaded) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                    'The document is ready, but automatic download is not available on this device.',
                  ),
                ),
              );
            }
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('We could not download that document right now.'),
              ),
            );
          }
        }

        void openPatientRecord() {
          context.go('/portal/$roleKey/customers?tab=records');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medical Records', style: AppTypography.h4),
            const SizedBox(height: 8),
            Text(
              selectedCustomer == null
                  ? 'Select a patient to review uploaded documents, reports, invoices, and care files.'
                  : 'Records for ${selectedCustomer.fullName}',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 16),
            _DocumentSection(
              title: 'Prescriptions',
              emptyMessage:
                  'No prescription files are linked to this patient yet.',
              documents: prescriptions,
              onOpen: openDocument,
              onDownload: downloadDocument,
              onOpenPatient: openPatientRecord,
            ),
            const SizedBox(height: 16),
            _DocumentSection(
              title: 'Lab Reports',
              emptyMessage: 'No lab reports have been uploaded yet.',
              documents: labReports,
              onOpen: openDocument,
              onDownload: downloadDocument,
              onOpenPatient: openPatientRecord,
            ),
            const SizedBox(height: 16),
            _DocumentSection(
              title: 'Invoices',
              emptyMessage: 'No invoice files are available yet.',
              documents: invoices,
              onOpen: openDocument,
              onDownload: downloadDocument,
              onOpenPatient: openPatientRecord,
            ),
            const SizedBox(height: 16),
            _DocumentSection(
              title: 'Other Records',
              emptyMessage:
                  'No other records are available for this patient yet.',
              documents: otherDocuments,
              onOpen: openDocument,
              onDownload: downloadDocument,
              onOpenPatient: openPatientRecord,
            ),
          ],
        );
      },
    );
  }
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({
    required this.title,
    required this.emptyMessage,
    required this.documents,
    required this.onOpen,
    required this.onDownload,
    required this.onOpenPatient,
  });

  final String title;
  final String emptyMessage;
  final List<dynamic> documents;
  final Future<void> Function(dynamic document) onOpen;
  final Future<void> Function(dynamic document) onDownload;
  final VoidCallback onOpenPatient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h5),
        const SizedBox(height: 8),
        if (documents.isEmpty)
          Text(
            emptyMessage,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          )
        else
          ...documents.map(
            (document) => Card(
              child: ListTile(
                onTap: () => onOpen(document),
                title: Text(document.fileName),
                subtitle: Text(
                  [document.typeLabel, document.extractionPreview]
                      .whereType<String>()
                      .where((value) => value.trim().isNotEmpty)
                      .join(' • '),
                ),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(document.statusLabel),
                    TextButton(
                      onPressed: () => onOpen(document),
                      child: const Text('Open'),
                    ),
                    TextButton(
                      onPressed: () => onDownload(document),
                      child: const Text('Download'),
                    ),
                    TextButton(
                      onPressed: onOpenPatient,
                      child: const Text('Patient'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
