import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/booking/data/customer_booking_repository.dart';
import 'package:shield/features/customer/booking/presentation/customer_booking_controller.dart';
import 'package:shield/features/customer/services/data/models/customer_provider.dart';
import 'package:shield/shared/models/appointment.dart';

void main() {
  test('maps supported provider request types without fabricating specialty results', () {
    expect(CustomerBookingRepository.appointmentTypeForProviderType('DENTAL'), 'DENTAL');
    expect(CustomerBookingRepository.appointmentTypeForProviderType('HOMECARE'), 'HOME_VISIT');
    expect(CustomerBookingRepository.appointmentTypeForProviderType('LABORATORY'), 'LAB');
    expect(CustomerBookingRepository.appointmentTypeForProviderType('CLINIC'), 'CLINIC');
    expect(CustomerBookingRepository.appointmentTypeForProviderType('DIETITIAN'), 'CLINIC');
    expect(CustomerBookingRepository.appointmentTypeForProviderType('COSMETIC'), 'CLINIC');
  });

  test(
    'restores an authoritative preselected provider and submits once',
    () async {
      final repository = _Repository();
      final controller = CustomerBookingController(repository: repository);

      await controller.restorePreselection('7');
      await controller.submit();
      await controller.submit();

      expect(controller.provider?.id, '7');
      expect(controller.completedAppointment?.id, '42');
      expect(repository.submissions, 1);
    },
  );

  test('rejects a preferred time that is already in the past', () async {
    final repository = _Repository();
    final controller = CustomerBookingController(repository: repository);
    controller.selectProvider(await repository.provider('7'));
    controller.setPreferredDateTime(
      DateTime.now().subtract(const Duration(minutes: 1)),
    );

    await controller.submit();

    expect(controller.completedAppointment, isNull);
    expect(repository.submissions, 0);
    expect(controller.error, isA<StateError>());
  });
}

class _Repository extends CustomerBookingRepository {
  int submissions = 0;

  @override
  Future<CustomerProvider> provider(String id) async => const CustomerProvider(
    id: '7',
    name: 'Active Clinic',
    type: 'CLINIC',
    typeLabel: 'Consultation',
    availabilityLabel: 'Active provider',
  );

  @override
  Future<Appointment> submit({
    required CustomerProvider provider,
    required DateTime preferredDateTime,
    String? notes,
  }) async {
    submissions++;
    return Appointment(
      id: '42',
      uuid: 'appointment-42',
      customerId: '1',
      providerId: provider.id,
      type: AppointmentType.clinic,
      appointmentDate: preferredDateTime,
      status: AppointmentStatus.scheduled,
      createdAt: preferredDateTime,
      updatedAt: preferredDateTime,
    );
  }
}
