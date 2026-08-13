import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/models/appointment.dart';
import 'package:shield/shared/services/api_service.dart';

void main() {
  test('preserves a customer rescheduled appointment response', () {
    final appointment = Appointment.fromJson(const {
      'id': '42',
      'customerId': '9',
      'appointmentType': 'CLINIC',
      'appointmentDate': '2026-08-12T10:30:00.000Z',
      'status': 'RESCHEDULED',
    });

    expect(appointment.status, AppointmentStatus.rescheduled);
    expect(appointment.statusLabel, 'Rescheduled');
  });

  test('preserves a pending customer appointment projection', () {
    final appointment = Appointment.fromJson(const {
      'id': '13',
      'customerId': '7',
      'providerId': '5',
      'appointmentType': 'DENTAL',
      'appointmentDate': '2026-08-13T10:30:00.000Z',
      'status': 'PENDING',
      'provider': {
        'id': '5',
        'providerName': 'Dentistry Melattur',
        'providerType': 'DENTAL',
      },
    });

    expect(appointment.id, '13');
    expect(appointment.status, AppointmentStatus.pending);
    expect(appointment.doctorName, 'Dentistry Melattur');
  });

  test('parses the documented successful customer appointments envelope', () {
    final appointments = ApiService.parseCustomerAppointmentListPayload({
      'success': true,
      'message': 'Appointments list retrieved',
      'data': [
        {
          'id': '13',
          'uuid': '00000000-0000-0000-0000-000000000013',
          'customerId': '7',
          'providerId': '5',
          'appointmentType': 'DENTAL',
          'appointmentDate': '2026-08-14T10:30:00.000Z',
          'status': 'PENDING',
          'remarks': null,
          'provider': {
            'id': '5',
            'providerName': 'Dentistry Melattur',
            'providerType': 'DENTAL',
          },
        },
      ],
    });

    expect(appointments.single.id, '13');
    expect(appointments.single.status, AppointmentStatus.pending);
    expect(appointments.single.doctorName, 'Dentistry Melattur');
  });

  test('rejects a malformed successful appointments payload', () {
    expect(
      () => ApiService.parseCustomerAppointmentListPayload({
        'success': true,
        'data': [
          {
            'id': '13',
            'customerId': '7',
            'appointmentType': 'DENTAL',
            'appointmentDate': 'not-a-date',
            'status': 'PENDING',
          },
        ],
      }),
      throwsFormatException,
    );
  });
}
