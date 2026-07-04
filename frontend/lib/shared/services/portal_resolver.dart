import 'package:flutter/foundation.dart';

import '../models/shield_role.dart';
import 'customer_auth_session.dart';
import 'internal_auth_session.dart';

class PortalResolution {
  const PortalResolution({
    required this.role,
    required this.isInternal,
  });

  final SHIELDRole role;
  final bool isInternal;

  String routeForSection([String section = 'dashboard']) {
    return '/portal/${role.routeKey}/$section';
  }
}

class PortalResolver {
  const PortalResolver._();

  static void _trace(String message) {
    debugPrint('[PortalResolver] $message');
  }

  static PortalResolution? get current {
    final internalSession = InternalAuthSession.instance;
    if (internalSession.isAuthenticated) {
      _trace(
        'current resolved internal role=${internalSession.homeRole.routeKey} roleCode=${internalSession.roleCode ?? 'unknown'}',
      );
      return PortalResolution(
        role: internalSession.homeRole,
        isInternal: true,
      );
    }

    if (CustomerAuthSession.instance.isAuthenticated) {
      _trace('current resolved customer role');
      return const PortalResolution(
        role: SHIELDRole.customer,
        isInternal: false,
      );
    }

    _trace('current resolved no authenticated portal');
    return null;
  }

  static String? guardPortalRoute({
    required String requestedRoleKey,
    required String sectionKey,
  }) {
    final resolution = current;
    if (resolution == null) {
      _trace(
        'guardPortalRoute allowed unauthenticated passthrough requestedRole=$requestedRoleKey section=$sectionKey',
      );
      return null;
    }

    final requestedRole = SHIELDRole.fromRouteKey(requestedRoleKey);
    if (requestedRole == resolution.role) {
      _trace(
        'guardPortalRoute allowed requestedRole=$requestedRoleKey section=$sectionKey',
      );
      return null;
    }

    _trace(
      'guardPortalRoute rerouting requestedRole=$requestedRoleKey section=$sectionKey to ${resolution.routeForSection(sectionKey)}',
    );
    return resolution.routeForSection(sectionKey);
  }

  static String resolvedHomeRoute() {
    final resolution = current;
    if (resolution == null) {
      _trace('resolvedHomeRoute fallback -> /customer/splash');
      return '/customer/splash';
    }
    final route = resolution.routeForSection();
    _trace('resolvedHomeRoute -> $route');
    return route;
  }

  static String routeForResolvedSection(
    String sectionKey, {
    String fallbackSection = 'dashboard',
  }) {
    final resolution = current;
    if (resolution == null) {
      _trace('routeForResolvedSection fallback -> /portal/customer/$sectionKey');
      return '/portal/customer/$sectionKey';
    }

    final role = resolution.role;
    if (_roleSupportsSection(role, sectionKey)) {
      final route = resolution.routeForSection(sectionKey);
      _trace('routeForResolvedSection exact -> $route');
      return route;
    }

    final fallbackRoute = resolution.routeForSection(fallbackSection);
    _trace(
      'routeForResolvedSection fallback for role=${role.routeKey} section=$sectionKey -> $fallbackRoute',
    );
    return fallbackRoute;
  }

  static bool _roleSupportsSection(SHIELDRole role, String sectionKey) {
    const adminSections = <String>{
      'dashboard',
      'customers',
      'agents',
      'crm',
      'visits',
      'documents',
      'memberships',
      'wallet',
      'rewards',
      'referrals',
      'providers',
      'services',
      'availability',
      'branches',
      'employees',
      'roles',
      'reports',
      'insights',
      'audit',
      'notifications',
      'settings',
      'platform',
    };

    if (role == SHIELDRole.superAdmin && adminSections.contains(sectionKey)) {
      return true;
    }

    switch (sectionKey) {
      case 'dashboard':
      case 'profile':
      case 'settings':
      case 'notifications':
        return true;
      case 'appointments':
      case 'documents':
        return role == SHIELDRole.customer ||
            role == SHIELDRole.agent ||
            role == SHIELDRole.provider;
      case 'membership':
      case 'services':
      case 'wallet':
      case 'prescriptions':
        return role == SHIELDRole.customer;
      case 'customers':
      case 'followups':
      case 'registration':
      case 'performance':
        return role == SHIELDRole.agent;
      case 'referrals':
        return role == SHIELDRole.agent;
      case 'reports':
        return role == SHIELDRole.agent || role == SHIELDRole.manager;
      default:
        return false;
    }
  }
}
