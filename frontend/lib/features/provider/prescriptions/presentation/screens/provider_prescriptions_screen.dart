import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../../../../shared/models/document.dart';
import '../../../../../../shared/services/platform_file_actions.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderPrescriptionsScreen extends StatelessWidget {
  const ProviderPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final roleKey =
            GoRouterState.of(context).pathParameters['role'] ?? 'provider';
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
                    onTap: () async {
                      final url = await controller.getPatientDocumentDownloadUrl(
                        document.id,
                      );
                      await openPlatformUrl(url);
                    },
                    title: Text(document.fileName),
                    subtitle: Text(
                      [
                        document.typeLabel,
                        document.extractionPreview,
                      ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' • '),
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(document.statusLabel),
                        TextButton(
                          onPressed: () async {
                            final url =
                                await controller.getPatientDocumentDownloadUrl(
                              document.id,
                            );
                            await openPlatformUrl(url);
                          },
                          child: const Text('Open'),
                        ),
                        TextButton(
                          onPressed: () => context.go(
                            '/portal/$roleKey/customers?tab=records',
                          ),
                          child: const Text('Patient'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
