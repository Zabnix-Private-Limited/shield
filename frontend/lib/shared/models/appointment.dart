import 'package:equatable/equatable.dart';

enum AppointmentType {
  clinic,
  dental,
  homeVisit,
}

enum AppointmentStatus {
  scheduled,
  completed,
  cancelled,
  rescheduled,
}

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
    appointmentDate: DateTime(2024, 6, 25, 10, 0),
    status: AppointmentStatus.scheduled,
    doctorName: 'Dr. Haneefa P',
    department: 'General Medicine - Perinthalmanna',
    notes: 'Regular checkup',
    createdAt: DateTime(2024, 6, 18),
    updatedAt: DateTime(2024, 6, 18),
  ),
  Appointment(
    id: '2',
    uuid: 'appt-002',
    customerId: '1',
    providerId: 'dental-1',
    type: AppointmentType.dental,
    appointmentDate: DateTime(2024, 6, 15, 14, 30),
    status: AppointmentStatus.completed,
    doctorName: 'Dr. Asna Basheer',
    department: 'Dentistry - Melattur',
    notes: 'Scaling and polishing',
    createdAt: DateTime(2024, 6, 10),
    updatedAt: DateTime(2024, 6, 15),
  ),
  Appointment(
    id: '3',
    uuid: 'appt-003',
    customerId: '1',
    providerId: 'clinic-2',
    type: AppointmentType.homeVisit,
    appointmentDate: DateTime(2024, 6, 28, 9, 0),
    status: AppointmentStatus.scheduled,
    doctorName: 'Dr. Jaseela K',
    department: 'Home Care - Alanallur',
    notes: 'Blood pressure check',
    createdAt: DateTime(2024, 6, 19),
    updatedAt: DateTime(2024, 6, 19),
  ),
  Appointment(
    id: '4',
    uuid: 'appt-004',
    customerId: '1',
    providerId: 'lab-1',
    type: AppointmentType.clinic,
    appointmentDate: DateTime(2024, 6, 8, 8, 30),
    status: AppointmentStatus.completed,
    doctorName: 'Tirur Lab Desk',
    department: 'Laboratory - Tirur',
    notes: 'CBC blood test',
    createdAt: DateTime(2024, 6, 5),
    updatedAt: DateTime(2024, 6, 8),
  ),
];
