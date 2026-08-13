import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/visits/data/customer_visits_repository.dart';
import 'package:shield/features/customer/visits/presentation/customer_visits_controller.dart';
import 'package:shield/shared/models/appointment.dart';

void main() {
  test('filters customer visits by backend status', () async {
    final controller = CustomerVisitsController(repository: _Repository());
    await controller.load();

    expect(controller.visible.map((item) => item.id), ['1']);
    controller.setFilter(CustomerVisitsFilter.completed);
    expect(controller.visible.map((item) => item.id), ['2']);
    controller.setFilter(CustomerVisitsFilter.cancelled);
    expect(controller.visible.map((item) => item.id), ['3']);
  });

  test('keeps pending customer requests in the upcoming visit list', () async {
    final controller = CustomerVisitsController(
      repository: _PendingRepository(),
    );
    await controller.load();

    expect(controller.visible.single.id, '13');
    expect(controller.visible.single.status, AppointmentStatus.pending);
    expect(controller.visible.single.statusLabel, 'Request pending');
  });
}

class _Repository extends CustomerVisitsRepository {
  @override
  Future<List<Appointment>> list() async => [
    _appointment('1', AppointmentStatus.scheduled),
    _appointment('2', AppointmentStatus.completed),
    _appointment('3', AppointmentStatus.cancelled),
  ];
}

Appointment _appointment(String id, AppointmentStatus status) => Appointment(
  id: id,
  uuid: 'appointment-$id',
  customerId: '1',
  type: AppointmentType.clinic,
  appointmentDate: DateTime(2026, 8, 9),
  status: status,
  createdAt: DateTime(2026, 8, 8),
  updatedAt: DateTime(2026, 8, 8),
);

class _PendingRepository extends CustomerVisitsRepository {
  @override
  Future<List<Appointment>> list() async => [
    _appointment('13', AppointmentStatus.pending),
  ];
}
