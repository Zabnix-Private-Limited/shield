import 'package:go_router/go_router.dart';
import '../../features/portal/presentation/screens/portal_shell.dart';
import '../../shared/models/shield_role.dart';

final GoRouter router = GoRouter(
  initialLocation: '/portal/customer/dashboard',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/portal/customer/dashboard',
    ),
    GoRoute(
      path: '/portal/:role',
      redirect: (context, state) {
        final roleKey =
            state.pathParameters['role'] ?? SHIELDRole.customer.routeKey;
        return '/portal/$roleKey/dashboard';
      },
    ),
    GoRoute(
      path: '/portal/:role/:section',
      name: 'role-portal',
      builder: (context, state) {
        final role = SHIELDRole.fromRouteKey(state.pathParameters['role']);
        final section = state.pathParameters['section'];
        return PortalShell(role: role, sectionKey: section);
      },
    ),
    GoRoute(
      path: '/documents',
      name: 'documents',
      redirect: (context, state) => '/portal/customer/documents',
    ),
    GoRoute(
      path: '/appointments',
      name: 'appointments',
      redirect: (context, state) => '/portal/customer/appointments',
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      redirect: (context, state) => '/portal/customer/notifications',
    ),
    GoRoute(
      path: '/prescriptions',
      name: 'prescriptions',
      redirect: (context, state) => '/portal/customer/prescriptions',
    ),
    GoRoute(
      path: '/membership',
      name: 'membership',
      redirect: (context, state) => '/portal/customer/membership',
    ),
    GoRoute(
      path: '/transactions',
      name: 'transactions',
      redirect: (context, state) => '/portal/customer/wallet',
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      redirect: (context, state) => '/portal/customer/settings',
    ),
    GoRoute(
      path: '/services',
      name: 'services',
      redirect: (context, state) => '/portal/customer/services',
    ),
    GoRoute(
      path: '/wallet',
      name: 'wallet',
      redirect: (context, state) => '/portal/customer/wallet',
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      redirect: (context, state) => '/portal/customer/profile',
    ),
    GoRoute(
      path: '/more',
      name: 'more',
      redirect: (context, state) => '/portal/customer/dashboard',
    ),
  ],
);
