import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final profile = controller.authProfile['profile'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final summary = controller.summary;
        final cards = <Map<String, dynamic>>[
          {
            'label': 'Today',
            'value': '${summary['appointmentsToday'] ?? 0}',
            'note': 'appointments',
          },
          {
            'label': 'Pending',
            'value': '${summary['pendingAppointments'] ?? 0}',
            'note': 'in queue',
          },
          {
            'label': 'Completed',
            'value': '${summary['completedToday'] ?? 0}',
            'note': 'today',
          },
          {
            'label': 'Revenue',
            'value': 'Rs ${summary['totalRevenue'] ?? 0}',
            'note': 'billed value',
          },
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.shieldNavy, AppColors.shieldBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provider workspace',
                    style: AppTypography.tiny.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (controller.authProfile['principal'] as Map<String, dynamic>? ??
                                const <String, dynamic>{})['roleCode']
                            ?.toString() ??
                        'SERVICE_PROVIDER',
                    style: AppTypography.h3.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim().isEmpty
                        ? 'Provisioned SHIELD workspace'
                        : '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim(),
                    style: AppTypography.body.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map(
                    (card) => Container(
                      width: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card['label'].toString(),
                            style: AppTypography.small.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            card['value'].toString(),
                            style: AppTypography.h4,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card['note'].toString(),
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('Incoming work', style: AppTypography.h4),
            const SizedBox(height: 12),
            ...controller.appointmentQueue.take(4).map(
              (item) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.divider),
                ),
                title: Text(item['title']?.toString() ?? ''),
                subtitle: Text(item['subtitle']?.toString() ?? ''),
                trailing: Text(item['status']?.toString() ?? ''),
              ),
            ),
          ],
        );
      },
    );
  }
}
