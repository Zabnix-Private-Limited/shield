import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'agent_portal_test_harness.dart';

void main() {
  final viewports = <({String name, Size size})>[
    (name: '1280x720', size: const Size(1280, 720)),
    (name: '1366x768', size: const Size(1366, 768)),
    (name: '1440x900', size: const Size(1440, 900)),
    (name: '1600x900', size: const Size(1600, 900)),
    (name: '1920x1080', size: const Size(1920, 1080)),
    (name: 'narrow-960x720', size: const Size(960, 720)),
  ];
  for (final screenCase in primaryAgentScreenCases) {
    for (final viewport in viewports) {
      testWidgets(
        '${screenCase.name} stays stable at ${viewport.name} textScale=1.0x',
        (tester) async {
          tester.view.physicalSize = viewport.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final controller = await createTestController();

          await tester.pumpWidget(
            buildAgentTestApp(
              controller: controller,
              child: screenCase.screen,
              width: viewport.size.width,
              textScaleFactor: 1,
            ),
          );

          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screenCase.name} ${viewport.name} 1.0x',
          );
        },
      );
    }
  }

  final largeTextCases = primaryAgentScreenCases
      .where(
        (screenCase) => const {
          'dashboard',
          'registration',
          'documents',
          'performance',
          'settings',
        }.contains(screenCase.name),
      )
      .toList();
  final largeTextViewports = viewports
      .where(
        (viewport) => const {
          '1280x720',
          '1600x900',
          'narrow-960x720',
        }.contains(viewport.name),
      )
      .toList();

  for (final screenCase in largeTextCases) {
    for (final viewport in largeTextViewports) {
      testWidgets(
        '${screenCase.name} stays stable at ${viewport.name} textScale=2.0x',
        (tester) async {
          tester.view.physicalSize = viewport.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final controller = await createTestController();

          await tester.pumpWidget(
            buildAgentTestApp(
              controller: controller,
              child: screenCase.screen,
              width: viewport.size.width,
              textScaleFactor: 2,
            ),
          );

          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screenCase.name} ${viewport.name} 2.0x',
          );
        },
      );
    }
  }
}
