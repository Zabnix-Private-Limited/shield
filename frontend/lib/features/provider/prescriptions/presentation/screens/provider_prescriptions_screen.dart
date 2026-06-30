import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../../../../shared/models/document.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderPrescriptionsScreen extends StatelessWidget {
  const ProviderPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final prescriptions = controller.selectedDocuments
            .where((document) => document.type == DocumentType.prescription)
            .toList();
        final selectedCustomer = controller.selectedCustomer;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prescriptions', style: AppTypography.h4),
            const SizedBox(height: 8),
            Text(
              selectedCustomer == null
                  ? 'Select a patient to review prescription-linked documents.'
                  : 'Prescription files for ${selectedCustomer.fullName}',
              style: AppTypography.small.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 12),
            if (prescriptions.isEmpty)
              Text(
                'No prescription-linked documents found for the selected patient.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              )
            else
              ...prescriptions.map(
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
      },
    );
  }
}
