import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/dashboard/domain/entities/dashboard_entity.dart';
import 'package:shield/features/customer/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:shield/features/customer/dashboard/presentation/widgets/greeting_header.dart';
import 'package:shield/shared/models/customer.dart';

void main() {
  final customer = Customer.fromJson(const {
    'id': '1',
    'uuid': 'customer-uuid',
    'customerCode': 'CUST-1',
    'firstName': 'Kannan',
    'mobile': '+917034479800',
    'status': 'ACTIVE',
    'createdAt': '2026-08-11T00:00:00.000Z',
    'updatedAt': '2026-08-11T00:00:00.000Z',
  });

  Widget subject(double width, MembershipApplicationEntity? application) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: GreetingHeader(
            customer: customer,
            membership: null,
            application: application,
            controller: DashboardController(),
          ),
        ),
      ),
    );
  }

  testWidgets('renders the compact no-application state on a narrow phone and opens request flow sheet', (
    tester,
  ) async {
    await tester.pumpWidget(subject(320, null));
    expect(find.text('No active membership card'), findsOneWidget);
    expect(find.text('Request membership'), findsOneWidget);

    // Tap Request membership button
    await tester.tap(find.text('Request membership'));
    await tester.pumpAndSettle();

    // Verify sheet modal opens with membership benefits & request options
    expect(find.text('Request SHIELD Membership'), findsOneWidget);
    expect(find.text('Submit Request'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders pending details without card or plan at tablet width', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        720,
        MembershipApplicationEntity(
          id: '1',
          reference: 'MAP-2026-TEST',
          status: 'PENDING',
          submittedAt: DateTime(2026, 8, 14),
        ),
      ),
    );
    expect(find.text('Membership application'), findsOneWidget);
    expect(find.text('MAP-2026-TEST'), findsOneWidget);
    expect(find.text('View application status'), findsOneWidget);
    expect(find.text('Digital card'), findsNothing);
    expect(find.text('Plan'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
