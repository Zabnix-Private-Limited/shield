import 'package:flutter/material.dart';

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
            .where(
              (document) => document.type == DocumentType.prescription,
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prescriptions', style: AppTypography.h4),
            const SizedBox(height: 12),
            if (prescriptions.isEmpty)
              const Text('No prescription-linked documents found for the selected customer.')
            else
              ...prescriptions.map(
                (document) => Card(
                  child: ListTile(
                    title: Text(document.fileName),
                    subtitle: Text(document.typeLabel),
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
