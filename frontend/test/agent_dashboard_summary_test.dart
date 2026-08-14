import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/agent/dashboard/presentation/screens/agent_dashboard_screen.dart';

import 'agent_portal_test_harness.dart';

void main() {
  testWidgets('renders customer-operation summary metrics from the Agent workspace', (tester) async {
    tester.view.physicalSize = const Size(1600, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = await createTestController();
    await tester.pumpWidget(buildAgentTestApp(controller: controller, child: const AgentDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Today’s Tasks'), findsOneWidget);
    expect(find.text('Pending registrations'), findsOneWidget);
    expect(find.text('Today’s follow-ups'), findsOneWidget);
    expect(find.text('Today’s customer count'), findsOneWidget);
    expect(find.text('Today’s visit count'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
