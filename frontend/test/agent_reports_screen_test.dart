import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/agent/reports/presentation/screens/agent_reports_screen.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_controller.dart';

import 'agent_portal_test_harness.dart';

void main() {
  testWidgets('renders the backend report registry and changes selected report', (tester) async {
    tester.view.physicalSize = const Size(1600, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = await createTestController();
    await tester.pumpWidget(buildAgentTestApp(controller: controller, child: const AgentReportsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Agent Activity Summary'), findsWidgets);
    expect(find.text('Follow-Up Status Report'), findsWidgets);
    await tester.tap(find.text('Follow-Up Status Report').first);
    await tester.pumpAndSettle();
    expect(find.text('Follow-Up Status Report'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the permission-safe empty state when registry is empty', (tester) async {
    tester.view.physicalSize = const Size(1600, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = AgentPortalController(_EmptyReportsRepository());
    await controller.refreshWorkspace();
    await tester.pumpWidget(buildAgentTestApp(controller: controller, child: const AgentReportsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No reports available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _EmptyReportsRepository extends AgentPortalTestRepository {
  @override
  Future<Map<String, dynamic>> getReportRegistry() async => const {'reports': <Map<String, dynamic>>[]};
}
