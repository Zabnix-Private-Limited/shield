import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/booking/data/customer_booking_repository.dart';
import 'package:shield/features/customer/booking/presentation/customer_booking_controller.dart';
import 'package:shield/features/customer/booking/presentation/customer_booking_screen.dart';
import 'package:shield/features/customer/services/data/models/customer_provider.dart';
import 'package:shield/features/customer/visits/data/customer_visits_repository.dart';
import 'package:shield/features/customer/visits/presentation/customer_visits_controller.dart';
import 'package:shield/features/customer/visits/presentation/customer_visits_screen.dart';
import 'package:shield/features/customer/shared/widgets/bottom_navigation.dart';
import 'package:shield/features/customer/shared/widgets/customer_scaffold.dart';
import 'package:shield/features/portal/presentation/screens/portal_shell.dart';
import 'package:shield/features/portal/presentation/portal_role_data.dart';
import 'package:shield/shared/models/appointment.dart';
import 'package:shield/shared/models/shield_role.dart';

void main() {
  testWidgets('booking and visits fit every required width', (tester) async {
    final booking = CustomerBookingController(repository: _BookingRepository());
    booking.selectProvider(
      const CustomerProvider(
        id: '1',
        name: 'Active Clinic',
        type: 'CLINIC',
        typeLabel: 'Consultation',
        availabilityLabel: 'Active provider',
      ),
    );
    final visits = CustomerVisitsController(repository: _VisitsRepository());

    for (final width in const [
      350.0,
      375.0,
      390.0,
      412.0,
      448.0,
      480.0,
      768.0,
      1200.0,
    ]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CustomerBookingScreen(controller: booking)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'booking width: $width');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CustomerVisitsScreen(controller: visits)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Visits'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'visits width: $width');
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets(
    'booking owns vertical scrolling within the customer portal shell',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: PortalShell(
            role: SHIELDRole.customer,
            sectionKey: 'book-appointment',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book a visit'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    },
  );

  testWidgets(
    'booking retains Services and visits retain Visits in bottom navigation',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomerBottomNavigation(
              activeSectionKey: 'book-appointment',
            ),
          ),
        ),
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomerBottomNavigation(
              activeSectionKey: 'appointments',
            ),
          ),
        ),
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
    },
  );

  testWidgets('visits owns vertical scrolling in the customer scaffold', (
    tester,
  ) async {
    final portal = portalDataForRole(SHIELDRole.customer);
    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerScaffold(
          portal: portal,
          section: portal.sectionFor('appointments'),
          activeSectionKey: 'appointments',
          body: CustomerVisitsScreen(
            controller: CustomerVisitsController(
              repository: _VisitsRepository(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Visits'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}

class _BookingRepository extends CustomerBookingRepository {}

class _VisitsRepository extends CustomerVisitsRepository {
  @override
  Future<List<Appointment>> list() async => [
    Appointment(
      id: '1',
      uuid: 'visit-1',
      customerId: '1',
      type: AppointmentType.clinic,
      appointmentDate: DateTime(2026, 8, 9, 10),
      status: AppointmentStatus.scheduled,
      doctorName:
          'A very long active provider name for responsive verification',
      createdAt: DateTime(2026, 8, 8),
      updatedAt: DateTime(2026, 8, 8),
    ),
  ];
}
