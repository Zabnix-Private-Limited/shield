import 'package:flutter/material.dart';

import '../../../../../../app/theme/app_typography.dart';
import '../../../shared/presentation/widgets/provider_workspace_scaffold.dart';

class ProviderAppointmentsScreen extends StatelessWidget {
  const ProviderAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWorkspaceScaffold(
      builder: (context, ref, controller) {
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
                    title: Text(appointment.typeLabel),
                    subtitle: Text(
                      '${appointment.doctorName ?? 'Provider'} • ${appointment.appointmentDate}',
                    ),
                    trailing: Text(appointment.statusLabel),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
