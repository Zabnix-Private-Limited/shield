import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shield/features/customer/booking/data/customer_booking_repository.dart';
import 'package:shield/features/customer/booking/presentation/customer_booking_controller.dart';
import 'package:shield/features/customer/booking/presentation/customer_booking_screen.dart';
import 'package:shield/features/customer/services/data/models/customer_provider.dart';
import 'package:shield/features/customer/services/presentation/controllers/customer_services_controller.dart';
import 'package:shield/features/customer/services/presentation/screens/customer_services_screen.dart';

void main() {
  testWidgets(
    'renders active provider categories and truthful detail boundary',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerServicesScreen(controller: _Controller()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Pharmacy'), findsOneWidget);
      expect(find.text('Active Pharmacy'), findsOneWidget);
      await tester.tap(find.text('Active Pharmacy'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('not available in the current customer contract'),
        findsOneWidget,
      );
    },
  );

  testWidgets('stays within every required responsive width', (tester) async {
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
          home: Scaffold(
            body: CustomerServicesScreen(controller: _Controller()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Pharmacy'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'width: $width');
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('passes the resolved provider ID from Services to Booking', (
    tester,
  ) async {
    final booking = CustomerBookingController(repository: _BookingRepository());
    final router = GoRouter(
      initialLocation: '/services',
      routes: [
        GoRoute(
          path: '/services',
          builder: (_, __) => Scaffold(
            body: CustomerServicesScreen(controller: _ClinicController()),
          ),
        ),
        GoRoute(
          path: '/portal/customer/book-appointment',
          builder: (_, __) =>
              Scaffold(body: CustomerBookingScreen(controller: booking)),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Active Clinic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to booking'));
    await tester.pumpAndSettle();

    expect(find.text('Book a visit'), findsOneWidget);
    expect(booking.provider?.id, 'clinic-1');
    expect(tester.takeException(), isNull);
  });
}

class _Controller extends CustomerServicesController {
  @override
  Future<void> load({String? query, String? type}) async {
    categories = const [
      CustomerProviderCategory(
        code: 'PHARMACY',
        label: 'Pharmacy',
        providerCount: 1,
      ),
    ];
    page = const CustomerProviderPage(
      items: [
        CustomerProvider(
          id: '1',
          name: 'Active Pharmacy',
          type: 'PHARMACY',
          typeLabel: 'Pharmacy',
          availabilityLabel: 'Available',
          businessName: 'SHIELD Health',
        ),
      ],
      page: 1,
      totalPages: 1,
    );
    isLoading = false;
    error = null;
    notifyListeners();
  }

  @override
  Future<CustomerProvider> provider(String id) async => page.items.single;
}

class _ClinicController extends _Controller {
  @override
  Future<void> load({String? query, String? type}) async {
    categories = const [
      CustomerProviderCategory(
        code: 'CLINIC',
        label: 'Clinic',
        providerCount: 1,
      ),
    ];
    page = const CustomerProviderPage(
      items: [
        CustomerProvider(
          id: 'clinic-1',
          name: 'Active Clinic',
          type: 'CLINIC',
          typeLabel: 'Consultation',
          availabilityLabel: 'Available',
        ),
      ],
      page: 1,
      totalPages: 1,
    );
    isLoading = false;
    error = null;
    notifyListeners();
  }
}

class _BookingRepository extends CustomerBookingRepository {
  @override
  Future<CustomerProvider> provider(String id) async => const CustomerProvider(
    id: 'clinic-1',
    name: 'Active Clinic',
    type: 'CLINIC',
    typeLabel: 'Consultation',
    availabilityLabel: 'Available',
  );
}
