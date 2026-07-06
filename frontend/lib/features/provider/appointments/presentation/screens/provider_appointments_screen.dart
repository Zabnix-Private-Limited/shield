import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderAppointmentsScreen extends StatelessWidget {
  const ProviderAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
        final roleKey =
            GoRouterState.of(context).pathParameters['role'] ?? 'provider';
        final appointments = controller.selectedAppointments;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appointments', style: AppTypography.h4),
            const SizedBox(height: 12),
            if (appointments.isEmpty)
              const Text('Select a customer to view appointment history.')
            else
              ...appointments.map(
                (appointment) => Card(
                  child: ListTile(
                    onTap: () async {
                      await controller.openAppointmentWorkflow(
                        appointment,
                        loadConsultation: true,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      context.go('/portal/$roleKey/customers?tab=today-visit');
                    },
                    title: Text(appointment.typeLabel),
                    subtitle: Text(
                      '${appointment.doctorName ?? 'Provider'} • ${appointment.appointmentDate}',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(appointment.statusLabel),
                        TextButton(
                          onPressed: () async {
                            await controller.openAppointmentWorkflow(
                              appointment,
                              loadConsultation: false,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            context.go(
                              '/portal/$roleKey/customers?tab=overview',
                            );
                          },
                          child: const Text('Patient'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await controller.openAppointmentWorkflow(
                              appointment,
                              loadConsultation: true,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            context.go(
                              '/portal/$roleKey/customers?tab=today-visit',
                            );
                          },
                          child: Text(
                            appointment.statusLabel.toLowerCase().contains(
                                  'completed',
                                )
                                ? 'View Visit'
                                : 'Open Visit',
                          ),
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
