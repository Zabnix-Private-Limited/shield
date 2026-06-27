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

final List<Appointment> dummyAppointments = [
  Appointment(
    id: '1',
    uuid: 'appt-001',
    customerId: '1',
    providerId: 'clinic-1',
    type: AppointmentType.clinic,
    appointmentDate: DateTime(2026, 6, 21, 10, 0),
    status: AppointmentStatus.scheduled,
    doctorName: 'Dr. Haneefa P',
    department: 'General Medicine - Perinthalmanna',
    notes: 'Regular checkup',
    createdAt: DateTime(2026, 6, 18),
    updatedAt: DateTime(2026, 6, 20),
  ),
  Appointment(
    id: '2',
    uuid: 'appt-002',
    customerId: '1',
    providerId: 'dental-1',
    type: AppointmentType.dental,
    appointmentDate: DateTime(2026, 6, 14, 14, 30),
    status: AppointmentStatus.completed,
    doctorName: 'Dr. Asna Basheer',
    department: 'Dentistry - Melattur',
    notes: 'Scaling and polishing',
    createdAt: DateTime(2026, 6, 10),
    updatedAt: DateTime(2026, 6, 14),
  ),
  Appointment(
    id: '3',
    uuid: 'appt-003',
    customerId: '1',
    providerId: 'clinic-2',
    type: AppointmentType.homeVisit,
    appointmentDate: DateTime(2026, 6, 24, 9, 0),
    status: AppointmentStatus.scheduled,
    doctorName: 'Dr. Jaseela K',
    department: 'Home Care - Alanallur',
    notes: 'Blood pressure check',
    createdAt: DateTime(2026, 6, 19),
    updatedAt: DateTime(2026, 6, 20),
  ),
  Appointment(
    id: '4',
    uuid: 'appt-004',
    customerId: '1',
    providerId: 'lab-1',
    type: AppointmentType.clinic,
    appointmentDate: DateTime(2026, 6, 8, 8, 30),
    status: AppointmentStatus.completed,
    doctorName: 'Tirur Lab Desk',
    department: 'Laboratory - Tirur',
    notes: 'CBC blood test',
    createdAt: DateTime(2026, 6, 5),
    updatedAt: DateTime(2026, 6, 8),
  ),
];
