import 'dart:async';

import 'package:dio/dio.dart';
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

  test('does not let a slower refresh overwrite newer visits', () async {
    final repository = _DeferredRepository();
    final controller = CustomerVisitsController(repository: repository);

    final firstLoad = controller.load();
    final secondLoad = controller.load();
    repository.requests[1].complete([
      _appointment('13', AppointmentStatus.pending),
    ]);
    await secondLoad;
    repository.requests[0].complete([]);
    await firstLoad;

    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
    expect(controller.appointments.single.id, '13');
  });

  test(
    'classifies offline, unauthorized, and malformed Visits failures',
    () async {
      final offline = CustomerVisitsController(
        repository: _FailingRepository(
          DioException(
            requestOptions: RequestOptions(path: '/appointments'),
            type: DioExceptionType.connectionError,
          ),
        ),
      );
      final unauthorized = CustomerVisitsController(
        repository: _FailingRepository(
          DioException(
            requestOptions: RequestOptions(path: '/appointments'),
            response: Response(
              statusCode: 401,
              requestOptions: RequestOptions(),
            ),
          ),
        ),
      );
      final malformed = CustomerVisitsController(
        repository: _FailingRepository(const FormatException('invalid data')),
      );

      await offline.load();
      await unauthorized.load();
      await malformed.load();

      expect(offline.errorKind, CustomerVisitsErrorKind.offline);
      expect(unauthorized.errorKind, CustomerVisitsErrorKind.unauthorized);
      expect(malformed.errorKind, CustomerVisitsErrorKind.malformed);
    },
  );
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

class _DeferredRepository extends CustomerVisitsRepository {
  final requests = <Completer<List<Appointment>>>[];

  @override
  Future<List<Appointment>> list() {
    final request = Completer<List<Appointment>>();
    requests.add(request);
    return request.future;
  }
}

class _FailingRepository extends CustomerVisitsRepository {
  _FailingRepository(this.failure);
  final Object failure;

  @override
  Future<List<Appointment>> list() => Future.error(failure);
}
