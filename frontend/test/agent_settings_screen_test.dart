import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/agent/settings/presentation/screens/agent_settings_screen.dart';
import 'package:shield/features/agent/shared/data/agent_portal_repository.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_controller.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_provider.dart';

void main() {
  testWidgets(
    'my account stays focused on identity instead of settings tabs',
    (tester) async {
      final controller = AgentPortalController(_FakeAgentSettingsRepository());
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
                height: 1200,
                child: AgentSettingsScreen(profileOnly: true),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Account'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Employee Information'), findsOneWidget);
      expect(find.text('Preferences'), findsNothing);
      expect(find.text('Security'), findsNothing);
    },
  );

  testWidgets(
    'settings screen keeps preferences and security without profile form duplication',
    (tester) async {
      final controller = AgentPortalController(_FakeAgentSettingsRepository());
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
                height: 1200,
                child: AgentSettingsScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Workspace'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Personal Information'), findsNothing);
      expect(find.text('Employee Information'), findsNothing);
    },
  );
}

class _FakeAgentSettingsRepository extends AgentPortalRepository {
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
      };

  @override
  Future<Map<String, dynamic>> getCurrentProfile() async => {
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
      };

  @override
  Future<Map<String, dynamic>> getCurrentPreferences() async => {
        'preferences': {
          'theme': 'system',
          'language': 'en',
          'timezone': 'Asia/Calcutta',
          'availability': {
            'mode': 'FIELD',
            'availableForAssignments': true,
          },
          'workingHours': {
            'startTime': '09:00',
            'endTime': '18:00',
          },
          'workingArea': {
            'label': 'Perinthalmanna',
            'district': 'Malappuram',
            'travelRadiusKm': 15,
          },
          'emergencyContact': {
            'name': 'Rahul',
            'phone': '9999999999',
            'relation': 'Brother',
          },
          'notifications': {
            'followUpReminders': true,
            'appointmentChanges': true,
            'referralUpdates': true,
            'membershipReminders': true,
          },
          'dashboardLayout': {
            'defaultView': 'overview',
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
          'assignments': const [
            {
              'business': {'name': 'Perinthalmanna Branch'},
              'status': 'ACTIVE',
              'isPrimary': true,
            },
          ],
        },
        'lookups': {
          'branches': const [
            {'id': 'b1', 'name': 'Perinthalmanna Branch', 'code': 'PMNA'},
          ],
        },
      };

  @override
  Future<List<Map<String, dynamic>>> getSessions() async => const [
        {
          'isCurrent': true,
          'loginMethod': 'Google',
          'device': {'deviceName': 'Office Laptop'},
        },
      ];

  @override
  Future<List<Map<String, dynamic>>> getLoginHistory() async => const [
        {
          'status': 'SUCCESS',
          'createdAt': '2026-07-03 09:15 IST',
          'loginMethod': 'Google',
        },
      ];

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
