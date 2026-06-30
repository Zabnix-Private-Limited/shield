import 'package:equatable/equatable.dart';

enum AppointmentType { clinic, dental, homeVisit }

enum AppointmentStatus { scheduled, completed, cancelled, rescheduled }

class Appointment extends Equatable {
  final String id;
  final String uuid;
  final String customerId;
  final String? providerId;
  final AppointmentType type;
  final DateTime appointmentDate;
  final AppointmentStatus status;
  final String? doctorName;
  final String? department;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Appointment({
    required this.id,
    required this.uuid,
    required this.customerId,
    this.providerId,
    required this.type,
    required this.appointmentDate,
    required this.status,
    this.doctorName,
    this.department,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    AppointmentType parseType(String value) {
      switch (value.toUpperCase()) {
        case 'DENTAL':
          return AppointmentType.dental;
        case 'HOME_VISIT':
        case 'HOMECARE':
          return AppointmentType.homeVisit;
        default:
          return AppointmentType.clinic;
      }
    }

    AppointmentStatus parseStatus(String value) {
      switch (value.toUpperCase()) {
        case 'CONFIRMED':
        case 'SCHEDULED':
          return AppointmentStatus.scheduled;
        case 'COMPLETED':
          return AppointmentStatus.completed;
        case 'RESCHEDULED':
          return AppointmentStatus.rescheduled;
        case 'CANCELLED':
          return AppointmentStatus.cancelled;
        default:
          return AppointmentStatus.scheduled;
      }
    }

    final provider = json['provider'] as Map<String, dynamic>?;
    final date =
        DateTime.tryParse(
          (json['appointmentDate'] ?? json['appointment_date']).toString(),
        ) ??
        DateTime.now();

    return Appointment(
      id: json['id'].toString(),
      uuid: (json['uuid'] ?? 'appointment-${json['id']}').toString(),
      customerId: (json['customerId'] ?? json['customer_id'] ?? '').toString(),
      providerId: (json['providerId'] ?? json['provider_id'])?.toString(),
      type: parseType(
        (json['appointmentType'] ?? json['appointment_type'] ?? 'CLINIC')
            .toString(),
      ),
      appointmentDate: date,
      status: parseStatus((json['status'] ?? 'SCHEDULED').toString()),
      doctorName:
          provider?['providerName']?.toString() ??
          provider?['provider_name']?.toString(),
      department:
          provider?['providerType']?.toString() ??
          provider?['provider_type']?.toString(),
      notes: (json['remarks'] ?? json['notes'])?.toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? date).toString()) ?? date,
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? date).toString()) ?? date,
    );
  }

  String get typeLabel => switch (type) {
    AppointmentType.clinic => 'Clinic',
    AppointmentType.dental => 'Dental',
    AppointmentType.homeVisit => 'Home Visit',
  };

  String get statusLabel => switch (status) {
    AppointmentStatus.scheduled => 'Scheduled',
    AppointmentStatus.completed => 'Completed',
    AppointmentStatus.cancelled => 'Cancelled',
    AppointmentStatus.rescheduled => 'Rescheduled',
  };

  @override
  List<Object?> get props => [
    id,
    uuid,
    customerId,
    providerId,
    type,
    appointmentDate,
    status,
    doctorName,
    department,
    notes,
    createdAt,
    updatedAt,
  ];
}
