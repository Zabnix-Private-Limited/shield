import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/agent/dashboard/presentation/screens/agent_dashboard_screen.dart';
import 'package:shield/features/agent/settings/presentation/screens/agent_settings_screen.dart';

import 'agent_portal_test_harness.dart';

void main() {
  testWidgets('dashboard meets labeled tap target guideline', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = await createTestController();
    await tester.pumpWidget(
      buildAgentTestApp(
        controller: controller,
        child: const AgentDashboardScreen(),
        width: 1600,
      ),
    );

    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('settings meets labeled tap target guideline', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = await createTestController();
    await tester.pumpWidget(
      buildAgentTestApp(
        controller: controller,
        child: const DefaultTabController(
          length: 3,
          child: AgentSettingsScreen(),
        ),
        width: 1600,
      ),
    );

    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
