import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/agent/store_change/presentation/screens/agent_store_change_screen.dart';

void main() {
  testWidgets('renders the empty assigned-customer store-change queue', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AgentStoreChangeScreen(loadRequests: () async => const []),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Store Change Requests'), findsOneWidget);
    expect(find.text('No store change requests'), findsOneWidget);
  });

  testWidgets('renders a pending request with review actions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AgentStoreChangeScreen(loadRequests: () async => [
          {
            'id': '1',
            'status': 'PENDING',
            'reason': 'Closer to home',
            'customer': {'name': 'Asha Kumar'},
            'requestedProvider': {'name': 'Hyper Pharmacy Central'},
          },
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Asha Kumar'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });
}
