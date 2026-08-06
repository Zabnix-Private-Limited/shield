import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../shared/services/auth_redirect_notice.dart';
import '../../shared/services/active_auth_session.dart';
import '../../features/customer/auth/presentation/screens/customer_login_screen.dart';
import '../../features/customer/auth/presentation/screens/customer_otp_screen.dart';
import '../../features/customer/auth/presentation/screens/customer_register_screen.dart';
import '../../features/customer/auth/presentation/screens/customer_splash_screen.dart';
import '../../features/provider/auth/presentation/screens/internal_login_screen.dart';
import '../../features/portal/presentation/screens/portal_shell.dart';
import 'route_recovery_screen.dart';
import '../../shared/models/shield_role.dart';
import '../../shared/services/customer_auth_session.dart';
import '../../shared/services/internal_auth_session.dart';
import '../../shared/services/portal_resolver.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void _traceRouter(String message) {
  if (kDebugMode) {
    debugPrint('[AppRouter] $message');
  }
}

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  observers: [SentryNavigatorObserver()],
  refreshListenable: Listenable.merge([
    CustomerAuthSession.instance,
    InternalAuthSession.instance,
    AuthRedirectNotice.instance,
  ]),
  redirect: (context, state) {
    final isCustomerAuthenticated =
        CustomerAuthSession.instance.isAuthenticated;
    final isInternalAuthenticated =
        InternalAuthSession.instance.isAuthenticated;
    final isAuthenticated = isCustomerAuthenticated || isInternalAuthenticated;
    final resolvedPortal = PortalResolver.current;
    final authNotice = AuthRedirectNotice.instance;
    final location = state.matchedLocation;
    final isCustomerPortal =
        location.startsWith('/customer/') ||
        location.startsWith('/portal/customer') ||
        location == '/';
    const publicLocations = {
      '/',
      '/customer/splash',
      '/customer/login',
      '/customer/otp',
      '/customer/register',
      '/internal/login',
      '/session-expired',
    };
    final isPublicLocation = publicLocations.contains(location);
    if (authNotice.hasNotice && location != '/session-expired') {
      final kind = authNotice.sessionKind == ShieldSessionKind.internal
          ? 'internal'
          : 'customer';
      return '/session-expired?kind=$kind';
    }

    if (isAuthenticated &&
        (location == '/' || location == '/customer/splash')) {
      _traceRouter('redirecting authenticated root/splash to resolved home');
      return PortalResolver.resolvedHomeRoute();
    }

    if (!isAuthenticated && !isPublicLocation) {
      final next = Uri.encodeComponent(state.uri.toString());
      _traceRouter(
        'redirecting unauthenticated user away from $location to ${isCustomerPortal ? '/customer/login' : '/internal/login'}',
      );
      return isCustomerPortal
          ? '/customer/login?next=$next'
          : '/internal/login?next=$next';
    }

    if (isCustomerAuthenticated &&
        (location == '/customer/login' ||
            location == '/customer/otp' ||
            location == '/customer/register')) {
      final next = state.uri.queryParameters['next'];
      if (next != null && next.startsWith('/')) {
        _traceRouter('customer auth redirecting to requested next=$next');
        return next;
      }
      return PortalResolver.resolvedHomeRoute();
    }

    if (isInternalAuthenticated && location == '/internal/login') {
      final next = state.uri.queryParameters['next'];
      if (next != null && next.startsWith('/')) {
        _traceRouter('internal auth redirecting to requested next=$next');
        return next;
      }
      return PortalResolver.resolvedHomeRoute();
    }

    if (isCustomerAuthenticated && location == '/internal/login') {
      _traceRouter(
        'customer session blocked from internal login; redirecting home',
      );
      return PortalResolver.resolvedHomeRoute();
    }

    if (isCustomerAuthenticated &&
        location.startsWith('/portal/') &&
        !location.startsWith('/portal/customer')) {
      final segments = state.uri.pathSegments;
      final sectionKey = segments.length >= 3 ? segments[2] : 'dashboard';
      _traceRouter(
        'customer session blocked from non-customer portal route=$location section=$sectionKey',
      );
      return PortalResolver.routeForResolvedSection(sectionKey);
    }

    if (isInternalAuthenticated &&
        (location.startsWith('/customer/') ||
            location.startsWith('/portal/customer'))) {
      _traceRouter(
        'internal session blocked from customer route; redirecting home',
      );
      return PortalResolver.resolvedHomeRoute();
    }

    if (isAuthenticated && location.startsWith('/portal/')) {
      final segments = state.uri.pathSegments;
      if (segments.length >= 2) {
        final requestedRoleKey = segments[1];
        final sectionKey = segments.length >= 3 ? segments[2] : 'dashboard';
        final guardedRoute = PortalResolver.guardPortalRoute(
          requestedRoleKey: requestedRoleKey,
          sectionKey: sectionKey,
        );
        if (guardedRoute != null) {
          return guardedRoute;
        }
      }
    }

    if (isInternalAuthenticated &&
        resolvedPortal != null &&
        !resolvedPortal.isInternal) {
      _traceRouter(
        'internal auth resolved to non-internal portal; redirecting home',
      );
      return PortalResolver.resolvedHomeRoute();
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => PortalResolver.resolvedHomeRoute(),
    ),
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
      path: '/internal/login',
      name: 'internal-login',
      builder: (context, state) => const InternalLoginScreen(),
    ),
    GoRoute(
      path: '/session-expired',
      name: 'session-expired',
      builder: (context, state) {
        final kind = state.uri.queryParameters['kind'];
        final isInternal = kind == 'internal';
        return RouteRecoveryScreen(
          title: isInternal ? 'Staff Session Expired' : 'Session Expired',
          message: isInternal
              ? 'Your SHIELD internal access token expired or is no longer valid. You will be redirected to the internal sign-in page so you can continue securely.'
              : 'Your SHIELD member session expired or is no longer valid. You will be redirected to the login page so you can continue securely.',
          targetRoute: isInternal
              ? '/internal/login?reason=session-expired'
              : '/customer/login?reason=session-expired',
          targetLabel: isInternal
              ? 'Go To Internal Login'
              : 'Go To Member Login',
        );
      },
    ),
    GoRoute(
      path: '/portal/:role',
      redirect: (context, state) {
        final roleKey =
            state.pathParameters['role'] ?? SHIELDRole.customer.routeKey;
        return PortalResolver.guardPortalRoute(
              requestedRoleKey: roleKey,
              sectionKey: 'dashboard',
            ) ??
            '/portal/$roleKey/dashboard';
      },
    ),
    GoRoute(
      path: '/portal',
      redirect: (context, state) => PortalResolver.resolvedHomeRoute(),
    ),
    GoRoute(
      path: '/portal/customer/shop',
      name: 'customer-wellness-shop',
      redirect: (context, state) => '/portal/customer/services',
    ),
    GoRoute(
      path: '/portal/customer/membership/:detail',
      builder: (context, state) => PortalShell(
        role: SHIELDRole.customer,
        sectionKey: 'membership-${state.pathParameters['detail']}',
      ),
    ),
    GoRoute(
      path: '/portal/:role/:section',
      name: 'role-portal',
      builder: (context, state) {
        final requestedRole = SHIELDRole.fromRouteKey(
          state.pathParameters['role'],
        );
        final resolvedRole = PortalResolver.current?.role ?? requestedRole;
        final section = state.pathParameters['section'];
        return PortalShell(role: resolvedRole, sectionKey: section);
      },
    ),
    GoRoute(
      path: '/documents',
      name: 'documents',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('documents'),
    ),
    GoRoute(
      path: '/appointments',
      name: 'appointments',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('appointments'),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('notifications'),
    ),
    GoRoute(
      path: '/prescriptions',
      name: 'prescriptions',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('prescriptions'),
    ),
    GoRoute(
      path: '/membership',
      name: 'membership',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('membership'),
    ),
    GoRoute(
      path: '/transactions',
      name: 'transactions',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('wallet'),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('settings'),
    ),
    GoRoute(
      path: '/services',
      name: 'services',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('services'),
    ),
    GoRoute(
      path: '/wallet',
      name: 'wallet',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('wallet'),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('profile'),
    ),
    GoRoute(
      path: '/more',
      name: 'more',
      redirect: (context, state) =>
          PortalResolver.routeForResolvedSection('dashboard'),
    ),
  ],
  errorBuilder: (context, state) {
    final requestedPath = state.uri.toString();
    final isInternalPath = requestedPath.startsWith('/internal/');
    final hasCustomerSession = CustomerAuthSession.instance.isAuthenticated;
    final hasInternalSession = InternalAuthSession.instance.isAuthenticated;
    final targetRoute = hasInternalSession
        ? PortalResolver.resolvedHomeRoute()
        : hasCustomerSession
        ? PortalResolver.resolvedHomeRoute()
        : isInternalPath
        ? '/internal/login'
        : '/customer/splash';
    final targetLabel = hasInternalSession
        ? 'Open Portal Home'
        : hasCustomerSession
        ? 'Open Member Home'
        : isInternalPath
        ? 'Open Internal Login'
        : 'Open SHIELD Home';
    final message = isInternalPath
        ? 'The internal SHIELD page you requested is unavailable in the current app state or the link is outdated. You will be redirected to the correct internal access entry point.'
        : 'The SHIELD page you requested could not be opened. The link may be outdated or incomplete. You will be redirected to a safe starting point.';

    return RouteRecoveryScreen(
      title: 'Page Unavailable',
      message: message,
      targetRoute: targetRoute,
      targetLabel: targetLabel,
    );
  },
);
