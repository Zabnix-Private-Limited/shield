import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/widgets/portal_support.dart';

void main() {
  testWidgets('shows optional document actions in the details sheet', (
    tester,
  ) async {
    var opened = false;
    var downloaded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showPortalDetailsSheet(
              context,
              title: 'Report.pdf',
              subtitle: 'Available securely.',
              meta: 'Today',
              status: 'Approved',
              actionText: 'Open secure document',
              onAction: () => opened = true,
              secondaryActionText: 'Download',
              onSecondaryAction: () => downloaded = true,
            ),
            child: const Text('Details'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open secure document'));
    await tester.tap(find.text('Download'));

    expect(opened, isTrue);
    expect(downloaded, isTrue);
  });
}
