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
      expect(
        find.textContaining('no current subscription entitlement'),
        findsOneWidget,
      );
      expect(find.text('₹10000'), findsNothing);
    },
  );

  testWidgets('renders backend-derived subscription entitlement separately', (
    tester,
  ) async {
    final controller = MembershipController(
      customerId: '42',
      repository: _MembershipTestRepository(
        _membership(withSubscription: true),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: CustomerMembershipScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your contribution'), findsOneWidget);
    expect(find.text('SHIELD Benefit'), findsWidgets);
    expect(find.text('₹10,000'), findsOneWidget);
    expect(find.text('₹1,000'), findsWidgets);
    expect(find.textContaining('not a CASH wallet balance'), findsOneWidget);
  });

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

  testWidgets('labels cached membership data as offline-safe', (tester) async {
    final controller = MembershipController(
      customerId: '42',
      repository: _CachedMembershipRepository(_membership()),
    );
    await tester.pumpWidget(
      MaterialApp(home: CustomerMembershipScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Showing saved membership details'),
      findsOneWidget,
    );
  });

  testWidgets('renders a dedicated subscription view from the same contract', (
    tester,
  ) async {
    final controller = MembershipController(
      customerId: '42',
      repository: _MembershipTestRepository(
        _membership(withSubscription: true),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerMembershipScreen(
          controller: controller,
          focus: MembershipFocus.subscription,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subscription details'), findsOneWidget);
    expect(find.text('Your contribution'), findsOneWidget);
  });

  testWidgets('keeps membership content stable at 350 logical pixels', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(350, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = MembershipController(
      customerId: '42',
      repository: _MembershipTestRepository(
        _membership(withSubscription: true),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: CustomerMembershipScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('SHLD-00042'), findsWidgets);
    expect(tester.takeException(), isNull);
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

class _CachedMembershipRepository extends MembershipRepository {
  _CachedMembershipRepository(this.value);
  final MembershipModel value;
  @override
  Future<MembershipModel?> loadCachedMembership(String customerId) async =>
      value;
  @override
  Future<MembershipModel> refreshMembership(String customerId) async => value;
}

MembershipModel _membership({bool withSubscription = false}) =>
    MembershipModel.fromJson({
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
      'membershipStats': {
        'totalEarnedCredits': 100,
        'totalRedeemedCredits': 40,
      },
      if (withSubscription)
        'subscription': {
          'planName': 'SHIELD Privilege Plan',
          'status': 'ACTIVE',
          'customerContributionPaise': 1000000,
          'shieldBenefitPaise': 100000,
          'totalEntitlementPaise': 1100000,
          'currentAllocation': {
            'allocationPaise': 100000,
            'carryForwardPaise': 0,
            'usedPaise': 0,
            'remainingPaise': 100000,
          },
        },
    });
