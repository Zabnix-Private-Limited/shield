import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/visits/data/customer_visits_repository.dart';
import 'package:shield/features/customer/visits/presentation/customer_visits_controller.dart';
import 'package:shield/features/customer/visits/presentation/customer_visits_screen.dart';
import 'package:shield/shared/models/appointment.dart';

void main() {
  testWidgets('renders deterministic loading then empty visits states', (
    tester,
  ) async {
    final pending = Completer<List<Appointment>>();
    final controller = CustomerVisitsController(
      repository: _DeferredRepository(pending),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CustomerVisitsScreen(controller: controller)),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('My Visits'), findsOneWidget);
    expect(find.text('No Upcoming visits are available.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a recoverable error instead of a blank Visits surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerVisitsScreen(
            controller: CustomerVisitsController(
              repository: _FailingRepository(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visits unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DeferredRepository extends CustomerVisitsRepository {
  _DeferredRepository(this.pending);

  final Completer<List<Appointment>> pending;

  @override
  Future<List<Appointment>> list() => pending.future;
}

class _FailingRepository extends CustomerVisitsRepository {
  @override
  Future<List<Appointment>> list() =>
      Future.error(StateError('Unexpected appointment payload'));
}
