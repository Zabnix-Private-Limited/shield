import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/membership/data/models/membership_model.dart';
import 'package:shield/features/customer/membership/data/repositories/membership_repository.dart';
import 'package:shield/features/customer/membership/presentation/controllers/membership_controller.dart';
import 'package:shield/features/customer/membership/presentation/screens/membership_screen.dart';

void main() {
  testWidgets('renders the membership loading state before the API resolves', (
    tester,
  ) async {
    final pending = Completer<MembershipModel>();
    final controller = MembershipController(
      customerId: '42',
      repository: _PendingMembershipRepository(pending),
    );
    await tester.pumpWidget(
      MaterialApp(home: CustomerMembershipScreen(controller: controller)),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('membership-loading-skeleton')),
      findsOneWidget,
    );

    pending.complete(_membership());
    await tester.pumpAndSettle();
    expect(find.text('SHLD-00042'), findsWidgets);
  });

  testWidgets(
    'renders the API-backed membership identity and entitlement gap',
    (tester) async {
      final controller = MembershipController(
        customerId: '42',
        repository: _MembershipTestRepository(_membership()),
      );
      await tester.pumpWidget(
        MaterialApp(home: CustomerMembershipScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('SHLD-00042'), findsWidgets);
      expect(find.text('Subscription entitlement'), findsOneWidget);
      expect(find.textContaining('SHIELD Benefit'), findsOneWidget);
      expect(find.text('₹10000'), findsNothing);
    },
  );

  testWidgets('renders the membership API error state', (tester) async {
    final controller = MembershipController(
      customerId: '42',
      repository: _MembershipTestRepository(null),
    );
    await tester.pumpWidget(
      MaterialApp(home: CustomerMembershipScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Membership unavailable'), findsOneWidget);
  });
}

class _MembershipTestRepository extends MembershipRepository {
  _MembershipTestRepository(this.value);

  final MembershipModel? value;

  @override
  Future<MembershipModel?> loadCachedMembership(String customerId) async =>
      null;

  @override
  Future<MembershipModel> loadMembership(String customerId) async {
    if (value == null) throw StateError('Membership API unavailable');
    return value!;
  }
}

class _PendingMembershipRepository extends MembershipRepository {
  _PendingMembershipRepository(this.pending);

  final Completer<MembershipModel> pending;

  @override
  Future<MembershipModel?> loadCachedMembership(String customerId) async =>
      null;

  @override
  Future<MembershipModel> loadMembership(String customerId) => pending.future;
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
});
