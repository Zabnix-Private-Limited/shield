import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderDocumentsScreen extends StatelessWidget {
  const ProviderDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final selectedCustomer = controller.selectedCustomer;
        final prescriptions = controller.selectedPrescriptionDocuments;
        final labReports = controller.selectedLabReportDocuments;
        final invoices = controller.selectedInvoiceDocuments;
        final otherDocuments = controller.selectedOtherDocuments;
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
              emptyMessage: 'No prescription files are linked to this patient yet.',
              documents: prescriptions,
            ),
            const SizedBox(height: 16),
            _DocumentSection(
              title: 'Lab Reports',
              emptyMessage: 'No lab reports have been uploaded yet.',
              documents: labReports,
            ),
            const SizedBox(height: 16),
            _DocumentSection(
              title: 'Invoices',
              emptyMessage: 'No invoice files are available yet.',
              documents: invoices,
            ),
            const SizedBox(height: 16),
            _DocumentSection(
              title: 'Other Records',
              emptyMessage: 'No other records are available for this patient yet.',
              documents: otherDocuments,
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
  });

  final String title;
  final String emptyMessage;
  final List<dynamic> documents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h5),
        const SizedBox(height: 8),
        if (documents.isEmpty)
          Text(emptyMessage, style: AppTypography.small.copyWith(color: AppColors.gray))
        else
          ...documents.map(
            (document) => Card(
              child: ListTile(
                title: Text(document.fileName),
                subtitle: Text(
                  [
                    document.typeLabel,
                    document.extractionPreview,
                  ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' • '),
                ),
                trailing: Text(document.statusLabel),
              ),
            ),
          ),
      ],
    );
  }
}
