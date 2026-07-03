import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'agent_portal_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final screenCase in primaryAgentScreenCases) {
    testWidgets('${screenCase.name} matches the stabilized desktop golden', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = await createTestController();
      const boundaryKey = Key('golden-boundary');

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: buildAgentTestApp(
            controller: controller,
            child: screenCase.screen,
            width: 1600,
          ),
        ),
      );

      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/agent_portal/${screenCase.name}.png'),
      );
    });
  }
}
