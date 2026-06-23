import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/screens/customer_dashboard.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/prescriptions/presentation/screens/prescriptions_screen.dart';
import '../../features/membership/presentation/screens/membership_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/role_demo/presentation/screens/role_demo_shell.dart';
import '../../shared/models/shield_role.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/workspace/:role',
      redirect: (context, state) {
        final roleKey =
            state.pathParameters['role'] ?? SHIELDRole.customer.routeKey;
        return '/workspace/$roleKey/dashboard';
      },
    ),
    GoRoute(
      path: '/workspace/:role/:section',
      name: 'role-workspace',
      builder: (context, state) {
        final role = SHIELDRole.fromRouteKey(state.pathParameters['role']);
        final section = state.pathParameters['section'];
        return RoleDemoShell(role: role, sectionKey: section);
      },
    ),
    GoRoute(
      path: '/documents',
      name: 'documents',
      builder: (context, state) => const DocumentsScreen(),
    ),
    GoRoute(
      path: '/appointments',
      name: 'appointments',
      builder: (context, state) => const AppointmentsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/prescriptions',
      name: 'prescriptions',
      builder: (context, state) => const PrescriptionsScreen(),
    ),
    GoRoute(
      path: '/membership',
      name: 'membership',
      builder: (context, state) => const MembershipScreen(),
    ),
    GoRoute(
      path: '/transactions',
      name: 'transactions',
      builder: (context, state) => const TransactionsScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'dashboard',
              builder: (context, state) => const CustomerDashboard(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/wallet',
              name: 'wallet',
              builder: (context, state) => const WalletScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
