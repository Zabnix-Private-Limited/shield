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
        final display =
            controller.authProfile['display'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final branch =
            display['branch'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My profile', style: AppTypography.h4),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display['fullName']?.toString() ??
                          '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim(),
                    ),
                    const SizedBox(height: 8),
                    Text(display['designation']?.toString() ?? 'Provider'),
                    Text(branch['name']?.toString() ?? 'Branch not assigned'),
                    const SizedBox(height: 12),
                    Text('Email: ${display['email'] ?? principal['email'] ?? 'Not available'}'),
                    Text('Phone: ${display['mobile'] ?? principal['mobile'] ?? 'Not available'}'),
                    if ((display['departmentName']?.toString() ?? '').isNotEmpty)
                      Text('Department: ${display['departmentName']}'),
                    if ((display['employeeCode']?.toString() ?? '').isNotEmpty)
                      Text('Staff code: ${display['employeeCode']}'),
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
