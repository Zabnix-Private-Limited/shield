import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderDocumentsScreen extends StatelessWidget {
  const ProviderDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final documents = controller.selectedDocuments;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents', style: AppTypography.h4),
            const SizedBox(height: 12),
            if (documents.isEmpty)
              const Text('Select a customer to review uploaded documents.')
            else
              ...documents.map(
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
