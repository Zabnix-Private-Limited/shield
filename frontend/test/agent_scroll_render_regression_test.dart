import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/agent/appointments/presentation/screens/agent_appointments_screen.dart';
import 'package:shield/features/agent/customers/presentation/screens/agent_customers_screen.dart';
import 'package:shield/features/agent/dashboard/presentation/screens/agent_dashboard_screen.dart';
import 'package:shield/features/agent/documents/presentation/screens/agent_documents_screen.dart';
import 'package:shield/features/agent/followups/presentation/screens/agent_followups_screen.dart';
import 'package:shield/features/agent/notifications/presentation/screens/agent_notifications_screen.dart';
import 'package:shield/features/agent/performance/presentation/screens/agent_performance_screen.dart';
import 'package:shield/features/agent/referrals/presentation/screens/agent_referrals_screen.dart';
import 'package:shield/features/agent/registration/presentation/screens/agent_registration_screen.dart';
import 'package:shield/features/agent/reports/presentation/screens/agent_reports_screen.dart';
import 'package:shield/features/agent/settings/presentation/screens/agent_settings_screen.dart';
import 'package:shield/features/agent/shared/data/agent_portal_repository.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_controller.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_provider.dart';

void main() {
  final cases = <({String name, Widget screen})>[
    (name: 'dashboard', screen: const AgentDashboardScreen()),
    (name: 'customers', screen: const AgentCustomersScreen()),
    (name: 'registration', screen: const AgentRegistrationScreen()),
    (name: 'followups', screen: const AgentFollowUpsScreen()),
    (name: 'appointments', screen: const AgentAppointmentsScreen()),
    (name: 'documents', screen: const AgentDocumentsScreen()),
    (name: 'notifications', screen: const AgentNotificationsScreen()),
    (name: 'performance', screen: const AgentPerformanceScreen()),
    (name: 'referrals', screen: const AgentReferralsScreen()),
    (name: 'reports', screen: const AgentReportsScreen()),
    (name: 'account', screen: const AgentSettingsScreen(profileOnly: true)),
    (
      name: 'settings',
      screen: const DefaultTabController(
        length: 3,
        child: AgentSettingsScreen(),
      ),
    ),
  ];

  for (final testCase in cases) {
    testWidgets(
      '${testCase.name} renders inside the portal scroll shell without exceptions',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final controller = AgentPortalController(
          _ScrollSafeAgentPortalRepository(),
        );
        await controller.refreshWorkspace();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              agentPortalControllerProvider.overrideWith((ref) => controller),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(width: 1600, child: testCase.screen),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: testCase.screen.runtimeType.toString(),
        );
      },
    );
  }

  testWidgets(
    'settings screen falls back safely when backend preference values are outside the known design-system options',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = AgentPortalController(
        _ScrollSafeAgentPortalRepository(),
      );
      await controller.refreshWorkspace();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentPortalControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1400,
                child: DefaultTabController(
                  length: 3,
                  child: AgentSettingsScreen(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ScrollSafeAgentPortalRepository extends AgentPortalRepository {
  @override
  Future<Map<String, dynamic>> getWorkspace() async => {
    'summary': const <String, dynamic>{},
    'performance': const <String, dynamic>{},
    'customers': const <Map<String, dynamic>>[],
    'tasks': const <Map<String, dynamic>>[],
    'notifications': const <Map<String, dynamic>>[],
    'recentActivity': const <Map<String, dynamic>>[],
    'upcomingAppointments': const <Map<String, dynamic>>[],
    'authProfile': {
      'display': {
        'fullName': 'Asha Patel',
        'designation': 'Field Agent',
        'employeeCode': 'AG-102',
        'lastLoginAt': '2026-07-03 09:15 IST',
      },
      'profile': {
        'firstName': 'Asha',
        'lastName': 'Patel',
        'mobile': '9876543210',
        'email': 'asha@shield.test',
      },
    },
    'agentSettings': {
      'preferences': {
        'theme': 'sepia',
        'language': 'ta',
        'timezone': 'Asia/Kolkata',
        'availability': {'mode': 'ONSITE', 'availableForAssignments': true},
        'workingHours': {'startTime': '09:00', 'endTime': '18:00'},
        'workingArea': {
          'label': 'Perinthalmanna',
          'district': 'Malappuram',
          'travelRadiusKm': 15,
        },
        'dashboardLayout': {'defaultView': 'pipeline'},
      },
      'branchLifecycle': {
        'activeBranch': {'name': 'Perinthalmanna Branch'},
        'assignments': const <Map<String, dynamic>>[],
      },
      'lookups': {
        'branches': const [
          {'id': 'b1', 'name': 'Perinthalmanna Branch', 'code': 'PMNA'},
        ],
      },
    },
  };

  @override
  Future<Map<String, dynamic>> getCurrentProfile() async =>
      (await getWorkspace())['authProfile'] as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> getCurrentPreferences() async =>
      (await getWorkspace())['agentSettings'] as Map<String, dynamic>;

  @override
  Future<List<Map<String, dynamic>>> getSessions() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getLoginHistory() async => const [];

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
