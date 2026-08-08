import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/account/data/customer_account_repository.dart';
import 'package:shield/features/customer/account/presentation/screens/customer_account_screen.dart';

class _AccountRepository extends CustomerAccountRepository {
  const _AccountRepository();

  @override
  Future<List<Map<String, dynamic>>> addresses() async => [
    {
      'id': '1',
      'label': 'HOME',
      'addressLine1': 'A long customer address that should wrap safely',
      'city': 'Thiruvananthapuram',
      'state': 'Kerala',
      'pincode': '695001',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> dependents() async => [
    {
      'id': '2',
      'firstName': 'Ananya',
      'lastName': 'Kumar',
      'relation': 'Child',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> contacts() async => [
    {
      'id': '3',
      'name': 'Emergency Contact With A Long Name',
      'mobile': '9988776655',
      'contactType': 'EMERGENCY',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> pharmacies() async => [
    {
      'id': '4',
      'providerName': 'SHIELD Community Pharmacy With A Long Name',
      'business': {'name': 'SHIELD Health Services'},
    },
  ];

  @override
  Future<Map<String, dynamic>?> preferredProvider() async => {'id': '4'};
}

void main() {
  const widths = [350.0, 375.0, 390.0, 412.0, 448.0, 480.0, 768.0, 1200.0];

  testWidgets('account workspace fits populated records at required widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in widths) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey('account-$width'),
          overrides: [
            customerAccountRepositoryProvider.overrideWithValue(
              const _AccountRepository(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CustomerAccountScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Profile & family'),
        findsOneWidget,
        reason: 'width $width',
      );
      expect(
        find.text(
          'A long customer address that should wrap safely, Thiruvananthapuram, Kerala, 695001',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });

  testWidgets('family, contacts and pharmacy tabs expose supported records', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerAccountRepositoryProvider.overrideWithValue(
            const _AccountRepository(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CustomerAccountScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    expect(find.text('Ananya Kumar'), findsOneWidget);

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Contact With A Long Name'), findsOneWidget);

    await tester.tap(find.text('Pharmacy'));
    await tester.pumpAndSettle();
    expect(find.text('Preferred'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
