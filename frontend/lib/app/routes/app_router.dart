import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../features/customer/auth/presentation/screens/customer_login_screen.dart';
import '../../features/customer/auth/presentation/screens/customer_otp_screen.dart';
import '../../features/customer/auth/presentation/screens/customer_register_screen.dart';
import '../../features/customer/auth/presentation/screens/customer_splash_screen.dart';
import '../../features/portal/presentation/screens/portal_shell.dart';
import '../../shared/models/shield_role.dart';
import '../../shared/services/customer_auth_session.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/customer/splash',
  observers: [SentryNavigatorObserver()],
  refreshListenable: CustomerAuthSession.instance,
  redirect: (context, state) {
    final isAuthenticated = CustomerAuthSession.instance.isAuthenticated;
    final location = state.matchedLocation;
    const publicLocations = {
      '/',
      '/customer/splash',
      '/customer/login',
      '/customer/otp',
      '/customer/register',
    };
    final isPublicLocation = publicLocations.contains(location);

    if (!isAuthenticated && !isPublicLocation) {
      final next = Uri.encodeComponent(state.uri.toString());
      return '/customer/login?next=$next';
    }

    if (isAuthenticated &&
        (location == '/customer/login' ||
            location == '/customer/otp' ||
            location == '/customer/register')) {
      final next = state.uri.queryParameters['next'];
      if (next != null && next.startsWith('/')) {
        return next;
      }
      return '/portal/customer/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/customer/splash'),
    GoRoute(
      path: '/customer/splash',
      name: 'customer-splash',
      builder: (context, state) => const CustomerSplashScreen(),
    ),
    GoRoute(
      path: '/customer/login',
      name: 'customer-login',
      builder: (context, state) => const CustomerLoginScreen(),
    ),
    GoRoute(
      path: '/customer/otp',
      name: 'customer-otp',
      builder: (context, state) => const CustomerOtpScreen(),
    ),
    GoRoute(
      path: '/customer/register',
      name: 'customer-register',
      builder: (context, state) => const CustomerRegisterScreen(),
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
