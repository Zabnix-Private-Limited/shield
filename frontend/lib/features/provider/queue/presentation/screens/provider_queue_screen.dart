import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderQueueScreen extends StatelessWidget {
  const ProviderQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final queueItems = [
          ...controller.appointmentQueue,
          ...controller.billingQueue,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operations queue', style: AppTypography.h4),
            const SizedBox(height: 12),
            if (queueItems.isEmpty)
              const Text('No active provider work items right now.')
            else
              ...queueItems.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item['title']?.toString() ?? ''),
                    subtitle: Text(
                      '${item['subtitle'] ?? ''}\n${item['meta'] ?? ''}',
                    ),
                    trailing: Text(item['status']?.toString() ?? ''),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
