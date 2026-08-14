import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/agent/followups/presentation/screens/agent_followups_screen.dart';
import 'package:shield/features/agent/shared/data/agent_portal_repository.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_controller.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_provider.dart';

void main() {
  testWidgets(
    'shows a single workflow empty state instead of stacked empty panels',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = AgentPortalController(_FakeAgentPortalRepository());
      await controller.refreshWorkspace();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentPortalControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AgentFollowUpsScreen()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No Follow-Ups Yet'), findsOneWidget);
      expect(find.text('Nothing here'), findsNothing);
      expect(find.text('No history yet'), findsNothing);
    },
  );

  testWidgets('groups scoped follow-ups by overdue, today, and upcoming state', (tester) async {
    tester.view.physicalSize = const Size(1600, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = AgentPortalController(_PopulatedFollowUpsRepository());
    await controller.refreshWorkspace();
    await tester.pumpWidget(ProviderScope(overrides: [agentPortalControllerProvider.overrideWith((ref) => controller)], child: const MaterialApp(home: Scaffold(body: AgentFollowUpsScreen()))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Overdue'), findsWidgets);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Upcoming'), findsWidgets);
    expect(find.text('Customer selected for the next follow-up.'), findsNothing);
    expect(find.text('Choose a customer before creating a follow-up.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _PopulatedFollowUpsRepository extends _FakeAgentPortalRepository {
  @override
  Future<Map<String, dynamic>> getWorkspace() async {
    final now = DateTime.now();
    return {
      ...(await super.getWorkspace()),
      'tasks': [
        {'customerName': 'Asha Patel', 'status': 'PENDING', 'notes': 'Overdue call', 'dueDate': now.subtract(const Duration(days: 1)).toIso8601String()},
        {'customerName': 'Asha Patel', 'status': 'PENDING', 'notes': 'Today call', 'dueDate': now.toIso8601String()},
        {'customerName': 'Asha Patel', 'status': 'PENDING', 'notes': 'Upcoming call', 'dueDate': now.add(const Duration(days: 2)).toIso8601String()},
      ],
    };
  }
}

class _FakeAgentPortalRepository extends AgentPortalRepository {
  @override
  Future<Map<String, dynamic>> getWorkspace() async => {
        'customers': [
          {
            'id': 'cust-1',
            'firstName': 'Asha',
            'lastName': 'Patel',
          },
        ],
        'tasks': const <Map<String, dynamic>>[],
        'notifications': const <Map<String, dynamic>>[],
        'recentActivity': const <Map<String, dynamic>>[],
        'upcomingAppointments': const <Map<String, dynamic>>[],
        'summary': const <String, dynamic>{},
        'performance': const <String, dynamic>{},
      };

  @override
  Future<Map<String, dynamic>> getCustomerWorkspace(String customerId) async => {
        'customer': {
          'id': customerId,
          'firstName': 'Asha',
          'lastName': 'Patel',
        },
        'tasks': const <Map<String, dynamic>>[],
        'activities': const <Map<String, dynamic>>[],
      };

  @override
  Future<List<Map<String, dynamic>>> getProviders() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getBusinesses() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getMembershipTypes() async => const [];

  @override
  Future<Map<String, dynamic>> getReportRegistry() async =>
      const <String, dynamic>{'reports': <Map<String, dynamic>>[]};
}
