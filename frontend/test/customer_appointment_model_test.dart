import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/models/appointment.dart';

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
}
