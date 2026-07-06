import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/provider/customers/presentation/widgets/provider_customers_shell.dart';

void main() {
  testWidgets(
    'ProviderCustomersShell renders dense search and selection workflow',
    (tester) async {
      String? selectedCustomerId;
      String? selectedSuggestion;
      final controller = TextEditingController(text: 'Aru');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderCustomersShell(
              searchController: controller,
              searchHint: 'Search patients',
              searchHelper: 'Review one patient record at a time.',
              suggestions: const ['Search by name', 'Search by phone'],
              customers: const [
                {
                  'id': '1',
                  'fullName': 'Arun Thomas',
                  'customerCode': 'CUST-1001',
                  'membershipPlan': 'Gold',
                  'mobile': '9876543210',
                  'city': 'Kochi',
                  'district': 'Ernakulam',
                  'status': 'ACTIVE',
                  'updatedAt': '2026-07-06T12:00:00.000Z',
                },
              ],
              selectedCustomerId: '1',
              loading: false,
              onSearchChanged: (_) {},
              onSuggestionSelected: (value) {
                selectedSuggestion = value;
              },
              onCustomerSelected: (value) {
                selectedCustomerId = value;
              },
            ),
          ),
        ),
      );

      expect(find.text('Patient workspace'), findsOneWidget);
      expect(find.text('1 row selected'), findsOneWidget);
      expect(find.text('Arun Thomas\nCUST-1001'), findsOneWidget);

      await tester.tap(find.text('Search by phone'));
      await tester.pump();
      expect(selectedSuggestion, 'Search by phone');

      await tester.tap(find.text('Arun Thomas\nCUST-1001'));
      await tester.pump();
      expect(selectedCustomerId, '1');
    },
  );
}
