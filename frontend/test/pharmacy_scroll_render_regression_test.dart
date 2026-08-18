import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/widgets/app_page_frame.dart';
import 'package:shield/features/provider/dashboard/presentation/screens/pharmacy_dashboard_view.dart';
import 'package:shield/features/provider/pharmacy/presentation/screens/pharmacy_orders_screen.dart';
import 'package:shield/features/provider/pharmacy/presentation/screens/pharmacy_payment_details_screen.dart';
import 'package:shield/features/provider/pharmacy/presentation/screens/pharmacy_payments_screen.dart';
import 'package:shield/features/provider/pharmacy/presentation/screens/pharmacy_order_history_screen.dart';

void main() {
  final screens = <({String name, Widget screen})>[
    (name: 'PharmacyDashboardView', screen: const PharmacyDashboardView()),
    (name: 'PharmacyOrdersScreen', screen: const PharmacyOrdersScreen()),
    (name: 'PharmacyPaymentDetailsScreen', screen: const PharmacyPaymentDetailsScreen()),
    (name: 'PharmacyPaymentsScreen', screen: const PharmacyPaymentsScreen()),
    (name: 'PharmacyOrderHistoryScreen', screen: const PharmacyOrderHistoryScreen()),
  ];

  final viewports = <({String name, Size size})>[
    (name: 'Phone 360x800', size: const Size(360, 800)),
    (name: 'Large Phone 390x844', size: const Size(390, 844)),
    (name: 'Tablet 768x1024', size: const Size(768, 1024)),
    (name: 'Desktop 1440x900', size: const Size(1440, 900)),
  ];

  for (final s in screens) {
    for (final vp in viewports) {
      testWidgets(
        '${s.name} renders cleanly under portal shell constraints on ${vp.name}',
        (tester) async {
          tester.view.physicalSize = vp.size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.runAsync(() async {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: AppPageFrame(
                          maxWidth: 1240,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Portal Header ${s.name}'),
                              const SizedBox(height: 16),
                              s.screen,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            await tester.pump();
            await Future.delayed(const Duration(milliseconds: 100));
          });

          expect(tester.takeException(), isNull, reason: '${s.name} failed on ${vp.name}');
        },
      );
    }
  }
}
