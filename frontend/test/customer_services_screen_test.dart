import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
