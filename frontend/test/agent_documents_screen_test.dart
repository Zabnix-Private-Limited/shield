import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/agent/documents/presentation/screens/agent_documents_screen.dart';
import 'package:shield/features/agent/shared/data/agent_portal_repository.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_controller.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_provider.dart';

void main() {
  testWidgets(
    'shows an actionable empty state when no customer is selected for documents',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = AgentPortalController(_NoCustomerAgentPortalRepository());
      await controller.refreshWorkspace();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentPortalControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AgentDocumentsScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Choose a customer first'), findsOneWidget);
      expect(find.text('Open Customers'), findsWidgets);
      expect(find.text('No documents found'), findsNothing);
    },
  );
}

class _NoCustomerAgentPortalRepository extends AgentPortalRepository {
  @override
  Future<Map<String, dynamic>> getWorkspace() async => {
        'customers': const <Map<String, dynamic>>[],
        'tasks': const <Map<String, dynamic>>[],
        'notifications': const <Map<String, dynamic>>[],
        'recentActivity': const <Map<String, dynamic>>[],
        'upcomingAppointments': const <Map<String, dynamic>>[],
        'summary': const <String, dynamic>{},
        'performance': const <String, dynamic>{},
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
