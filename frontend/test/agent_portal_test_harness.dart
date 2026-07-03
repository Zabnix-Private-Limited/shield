import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shield/app/theme/app_theme.dart';
import 'package:shield/features/agent/customers/presentation/screens/agent_customers_screen.dart';
import 'package:shield/features/agent/dashboard/presentation/screens/agent_dashboard_screen.dart';
import 'package:shield/features/agent/documents/presentation/screens/agent_documents_screen.dart';
import 'package:shield/features/agent/followups/presentation/screens/agent_followups_screen.dart';
import 'package:shield/features/agent/notifications/presentation/screens/agent_notifications_screen.dart';
import 'package:shield/features/agent/performance/presentation/screens/agent_performance_screen.dart';
import 'package:shield/features/agent/reports/presentation/screens/agent_reports_screen.dart';
import 'package:shield/features/agent/registration/presentation/screens/agent_registration_screen.dart';
import 'package:shield/features/agent/settings/presentation/screens/agent_settings_screen.dart';
import 'package:shield/features/agent/shared/data/agent_portal_repository.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_controller.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_provider.dart';

typedef AgentScreenCase = ({String name, Widget screen});

final primaryAgentScreenCases = <AgentScreenCase>[
  (name: 'dashboard', screen: const AgentDashboardScreen()),
  (name: 'customers', screen: const AgentCustomersScreen()),
  (name: 'registration', screen: const AgentRegistrationScreen()),
  (name: 'followups', screen: const AgentFollowUpsScreen()),
  (name: 'documents', screen: const AgentDocumentsScreen()),
  (name: 'notifications', screen: const AgentNotificationsScreen()),
  (name: 'reports', screen: const AgentReportsScreen()),
  (name: 'performance', screen: const AgentPerformanceScreen()),
  (
    name: 'settings',
    screen: const DefaultTabController(length: 3, child: AgentSettingsScreen()),
  ),
];

Future<AgentPortalController> createTestController() async {
  final controller = AgentPortalController(AgentPortalTestRepository());
  await controller.refreshWorkspace();
  return controller;
}

Widget buildAgentTestApp({
  required AgentPortalController controller,
  required Widget child,
  double width = 1600,
  bool shellScroll = true,
  double textScaleFactor = 1,
}) {
  final body = SizedBox(width: width, child: child);
  return ProviderScope(
    overrides: [
      agentPortalControllerProvider.overrideWith((ref) => controller),
    ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: shellScroll
                ? CustomScrollView(slivers: [SliverToBoxAdapter(child: body)])
                : body,
          ),
        ),
      ),
    );
  }

class AgentPortalTestRepository extends AgentPortalRepository {
  @override
  Future<Map<String, dynamic>> getWorkspace() async => {
    'summary': const <String, dynamic>{
      'pendingRegistrations': 0,
      'pendingDocuments': 0,
      'todaysFollowUps': 0,
      'appointmentsToday': 0,
    },
    'performance': const <String, dynamic>{
      'retentionRate': 88,
      'conversionRate': 41,
      'followUpCompletion': 92,
      'customerSatisfaction': 96,
    },
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
        'theme': 'system',
        'language': 'en',
        'timezone': 'Asia/Calcutta',
        'availability': {'mode': 'FIELD', 'availableForAssignments': true},
        'workingHours': {'startTime': '09:00', 'endTime': '18:00'},
        'workingArea': {
          'label': 'Perinthalmanna',
          'district': 'Malappuram',
          'travelRadiusKm': 15,
        },
        'dashboardLayout': {'defaultView': 'overview'},
        'notifications': {
          'followUpReminders': true,
          'appointmentChanges': true,
          'referralUpdates': true,
          'membershipReminders': true,
        },
        'profilePreferences': {
          'showCustomerCodes': true,
          'showMembershipBadges': true,
        },
        'devicePreferences': {
          'preferredDeviceLabel': 'Office Laptop',
          'allowPushNotifications': true,
        },
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
  Future<List<Map<String, dynamic>>> getSessions() async => const [
    {
      'sessionId': 's1',
      'isCurrent': true,
      'loginMethod': 'Google',
      'device': {'deviceName': 'Office Laptop'},
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> getLoginHistory() async => const [
    {
      'status': 'SUCCESS',
      'createdAt': '2026-07-03T09:15:00.000Z',
      'loginMethod': 'Google',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> getProviders() async => const [
    {'id': 'p1', 'providerName': 'Dr. Arun Clinic'},
  ];

  @override
  Future<List<Map<String, dynamic>>> getBusinesses() async => const [
    {'id': 'b1', 'name': 'Perinthalmanna Branch', 'code': 'PMNA'},
  ];

  @override
  Future<List<Map<String, dynamic>>> getMembershipTypes() async => const [
    {'code': 'STANDARD', 'name': 'Standard'},
  ];

  @override
  Future<Map<String, dynamic>> getReportRegistry() async => const {
    'reports': [
      {
        'id': 'r1',
        'title': 'Agent Activity Summary',
        'description': 'Daily operational activity report.',
        'formats': ['PDF'],
      },
    ],
  };
}
