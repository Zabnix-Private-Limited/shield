import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/dashboard/presentation/widgets/recent_activity.dart';

void main() {
  testWidgets(
    'shows an explicit empty state instead of a blank dashboard area',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RecentActivity(transactions: [])),
        ),
      );

      expect(find.text('No recent activity'), findsOneWidget);
    },
  );
}
