import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shield/features/customer/membership/data/models/membership_model.dart';
import 'package:shield/features/customer/membership/data/repositories/membership_repository.dart';
import 'package:shield/features/customer/membership/presentation/controllers/membership_controller.dart';
import 'package:shield/features/customer/membership/presentation/screens/privilege_card_screen.dart';
import 'package:shield/shared/models/customer.dart';

void main() {
  testWidgets(
    'renders the server-issued QR card and hides unsupported request',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerPrivilegeCardScreen(
              controller: _controller(),
              loadCustomer: () async => _customer(),
              loadCardProfile: () async => const {'action': 'VIEW_CARD'},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SHLD-00042'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Request physical card'), findsNothing);
    },
  );

  testWidgets(
    'offers and submits a physical-card request only when supported',
    (tester) async {
      var requests = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerPrivilegeCardScreen(
              controller: _controller(),
              loadCustomer: () async => _customer(),
              loadCardProfile: () async => const {
                'action': 'REQUEST_PHYSICAL_CARD',
              },
              requestPhysicalCard: () async {
                requests++;
                return const {'status': 'PENDING'};
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final requestButton = find.text('Request physical card');
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
      await tester.tap(requestButton);
      await tester.pumpAndSettle();

      expect(requests, 1);
    },
  );

  testWidgets('shows retryable physical-card status failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerPrivilegeCardScreen(
            controller: _controller(),
            loadCustomer: () async => _customer(),
            loadCardProfile: () async => throw StateError('Unavailable'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Physical card status is unavailable right now.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}

MembershipController _controller() => MembershipController(
  customerId: '42',
  repository: _TestMembershipRepository(_membership()),
);

class _TestMembershipRepository extends MembershipRepository {
  _TestMembershipRepository(this.value);

  final MembershipModel value;

  @override
  Future<MembershipModel?> loadCachedMembership(String customerId) async =>
      null;

  @override
  Future<MembershipModel> loadMembership(String customerId) async => value;
}

MembershipModel _membership() => MembershipModel.fromJson(const {
  'customerId': '42',
  'membership': {
    'id': '7',
    'uuid': 'member-7',
    'membershipNumber': 'SHLD-00042',
    'status': 'ACTIVE',
    'activationDate': '2026-01-01T00:00:00.000Z',
    'expiryDate': '2027-01-01T00:00:00.000Z',
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
    'membershipType': {'name': 'Founding Member'},
  },
  'membershipStats': {'totalEarnedCredits': 100, 'totalRedeemedCredits': 40},
  'shieldCard': {
    'cardNumber': 'SHLD-CARD-00042',
    'qrCode': 'server-issued-qr-payload',
    'status': 'ACTIVE',
    'issuedAt': '2026-01-02T00:00:00.000Z',
  },
});

Customer _customer() => Customer.fromJson(const {
  'id': '42',
  'uuid': 'customer-42',
  'customerCode': 'SHLD-00042',
  'firstName': 'Rahul',
  'lastName': 'Muraleedharan',
  'mobile': '9876543210',
  'status': 'ACTIVE',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
});
