import 'package:equatable/equatable.dart';

enum AppointmentType { clinic, dental, homeVisit }

enum AppointmentStatus {
  pending,
  scheduled,
  checkedIn,
  inProgress,
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
        case 'PENDING':
        case 'REQUESTED':
        case 'WAITING':
          return AppointmentStatus.pending;
        case 'CONFIRMED':
        case 'SCHEDULED':
          return AppointmentStatus.scheduled;
        case 'CHECKED_IN':
          return AppointmentStatus.checkedIn;
        case 'IN_PROGRESS':
          return AppointmentStatus.inProgress;
        case 'COMPLETED':
          return AppointmentStatus.completed;
        case 'RESCHEDULED':
          return AppointmentStatus.rescheduled;
        case 'CANCELLED':
          return AppointmentStatus.cancelled;
        default:
          throw FormatException('Unsupported appointment status: $value');
      }
    }

    final id = json['id']?.toString().trim();
    if (id == null || id.isEmpty) {
      throw const FormatException('Appointment id is required.');
    }
    final rawProvider = json['provider'];
    if (rawProvider != null && rawProvider is! Map) {
      throw const FormatException('Appointment provider must be an object.');
    }
    final provider = rawProvider == null
        ? null
        : Map<String, dynamic>.from(rawProvider as Map);
    final rawDate = json['appointmentDate'] ?? json['appointment_date'];
    final date = rawDate == null ? null : DateTime.tryParse(rawDate.toString());
    if (date == null) {
      throw const FormatException(
        'Appointment date is required and must be valid.',
      );
    }
    final rawStatus = json['status']?.toString().trim();
    if (rawStatus == null || rawStatus.isEmpty) {
      throw const FormatException('Appointment status is required.');
    }

    return Appointment(
      id: id,
      uuid: (json['uuid'] ?? 'appointment-$id').toString(),
      customerId: (json['customerId'] ?? json['customer_id'] ?? '').toString(),
      providerId: (json['providerId'] ?? json['provider_id'])?.toString(),
      type: parseType(
        (json['appointmentType'] ?? json['appointment_type'] ?? 'CLINIC')
            .toString(),
      ),
      appointmentDate: date,
      status: parseStatus(rawStatus),
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
    AppointmentStatus.pending => 'Request pending',
    AppointmentStatus.scheduled => 'Scheduled',
    AppointmentStatus.checkedIn => 'Checked In',
    AppointmentStatus.inProgress => 'Consultation in Progress',
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
