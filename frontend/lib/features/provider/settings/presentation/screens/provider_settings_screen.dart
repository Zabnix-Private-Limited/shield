import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_typography.dart';
import '../../../../../../shared/services/internal_auth_session.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderSettingsScreen extends StatelessWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      loadSettings: true,
      builder: (context, ref, controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: AppTypography.h4),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Provider sign-in is managed through the shared SHIELD authentication flow. Session controls below are live. Password changes and advanced profile preferences remain managed by the authentication provider and platform settings.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: InternalAuthSession.instance.signOut,
              child: const Text('Sign out'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: controller.isSettingsLoading
                  ? null
                  : controller.revokeOtherOwnedSessions,
              child: const Text('Sign out other devices'),
            ),
            const SizedBox(height: 18),
            Text('Sessions', style: AppTypography.h5),
            const SizedBox(height: 8),
            ...controller.sessions.map(
              (session) => Card(
                child: ListTile(
                  title: Text(session['device']?['deviceName']?.toString() ?? 'Session'),
                  subtitle: Text(session['loginMethod']?.toString() ?? ''),
                  trailing: session['isCurrent'] == true
                      ? const Text('Current')
                      : TextButton(
                          onPressed: () => controller.revokeOwnedSession(
                            session['sessionId']?.toString() ?? '',
                          ),
                          child: const Text('Revoke'),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Login history', style: AppTypography.h5),
            const SizedBox(height: 8),
            ...controller.loginHistory.map(
              (row) => Card(
                child: ListTile(
                  title: Text(row['status']?.toString() ?? 'UNKNOWN'),
                  subtitle: Text(row['createdAt']?.toString() ?? ''),
                  trailing: Text(row['loginMethod']?.toString() ?? ''),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
