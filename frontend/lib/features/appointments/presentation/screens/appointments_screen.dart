import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/shield_role.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/portal_support.dart';
import '../../../../shared/services/api_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late Future<List<Appointment>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    setState(() {
      _appointmentsFuture = ApiService.getAppointments(SHIELDRole.customer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/portal/customer/book-appointment');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Appointment>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Failed to load appointments', style: AppTypography.h3),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: AppTypography.body),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Retry',
                      onPressed: _loadAppointments,
                    ),
                  ],
                ),
              ),
            );
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return PortalEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No appointments booked',
              description:
                  'Clinic, dental, and home-visit bookings will appear here as soon as the customer confirms a slot.',
              actionText: 'Book Appointment',
              onAction: () => context.go('/portal/customer/book-appointment'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadAppointments(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () {
                      showPortalDetailsSheet(
                        context,
                        title:
                            appointment.doctorName ??
                            appointment.department ??
                            'Appointment',
                        subtitle:
                            appointment.notes ??
                            'A scheduled care event is available in the member timeline.',
                        meta:
                            '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
                        status: _getStatusText(appointment.status),
                        highlights: [
                          'Service: ${appointment.type.name}',
                          if (appointment.department != null)
                            'Department: ${appointment.department!}',
                          'Created on ${appointment.createdAt.day}/${appointment.createdAt.month}/${appointment.createdAt.year}.',
                        ],
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _getTypeColor(
                              appointment.type,
                            ).withValues(alpha: 0.1),
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
                                appointment.doctorName ??
                                    appointment.department ??
                                    'Appointment',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year} • ${appointment.appointmentDate.hour}:${appointment.appointmentDate.minute.toString().padLeft(2, '0')}',
                                style: AppTypography.tiny.copyWith(
                                  color: AppColors.gray,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appointment.department ?? '',
                                style: AppTypography.small.copyWith(
                                  color: AppColors.shieldNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              appointment.status,
                            ).withValues(alpha: 0.1),
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
