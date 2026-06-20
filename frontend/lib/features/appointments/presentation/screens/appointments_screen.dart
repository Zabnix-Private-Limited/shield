import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/appointment.dart';
import '../../../../shared/widgets/app_card.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummyAppointments.length,
        itemBuilder: (context, index) {
          final appointment = dummyAppointments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () {},
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getTypeColor(appointment.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(appointment.type),
                      color: _getTypeColor(appointment.type),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctorName ?? appointment.department ?? 'Appointment',
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year} • ${appointment.appointmentDate.hour}:${appointment.appointmentDate.minute.toString().padLeft(2, '0')}',
                          style: AppTypography.tiny.copyWith(color: AppColors.gray),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.department ?? '',
                          style: AppTypography.small.copyWith(color: AppColors.shieldNavy),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(appointment.status),
                      style: AppTypography.tiny.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(appointment.status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getTypeIcon(AppointmentType type) {
    switch (type) {
      case AppointmentType.clinic:
        return Icons.local_hospital;
      case AppointmentType.dental:
        return Icons.medical_services;
      case AppointmentType.homeVisit:
        return Icons.house;
    }
  }

  Color _getTypeColor(AppointmentType type) {
    switch (type) {
      case AppointmentType.clinic:
        return AppColors.shieldBlue;
      case AppointmentType.dental:
        return AppColors.warning;
      case AppointmentType.homeVisit:
        return AppColors.shieldGreen;
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return AppColors.shieldBlue;
      case AppointmentStatus.completed:
        return AppColors.shieldGreen;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.rescheduled:
        return AppColors.warning;
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
    }
  }
}
