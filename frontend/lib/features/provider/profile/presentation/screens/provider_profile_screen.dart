import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final principal =
            controller.authProfile['principal'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final profile =
            controller.authProfile['profile'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: AppTypography.h4),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim(),
                    ),
                    Text('Email: ${principal['email'] ?? 'Not available'}'),
                    Text('Role: ${principal['roleCode'] ?? 'Unknown'}'),
                    Text(
                      'Branch business: ${principal['branchBusinessId'] ?? 'Unassigned'}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
