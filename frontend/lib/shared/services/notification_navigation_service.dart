import 'package:flutter/foundation.dart';
import '../../app/routes/app_router.dart';

class NotificationNavigationService {
  NotificationNavigationService._();
  static String? _pendingRoute;

  static const _customerSections = <String>{
    'dashboard', 'wallet', 'wallet-history', 'rewards', 'services', 'orders',
    'referrals', 'activity', 'appointments', 'documents', 'profile', 'account',
    'membership', 'privilege-card', 'prescriptions', 'book-appointment',
    'settings', 'notifications', 'support', 'store-change',
  };

  static String resolveCustomerRoute(Map<String, dynamic> data) {
    final explicitRoute = data['route']?.toString().trim();
    if (explicitRoute != null && explicitRoute.startsWith('/portal/customer/')) {
      final section = Uri.tryParse(explicitRoute)?.pathSegments.last;
      if (section != null && _customerSections.contains(section)) return explicitRoute;
    }
    final section = data['section']?.toString().trim();
    if (section != null && _customerSections.contains(section)) {
      return '/portal/customer/$section';
    }
    return '/portal/customer/notifications';
  }

  static void handleCustomerPush(Map<String, dynamic> data) {
    final route = resolveCustomerRoute(data);
    if (kDebugMode) debugPrint('SHIELD push navigation resolved route=$route');
    if (rootNavigatorKey.currentContext == null) {
      _pendingRoute = route;
      return;
    }
    router.go(route);
  }

  static void flushPendingNavigation() {
    final route = _pendingRoute;
    if (route == null || rootNavigatorKey.currentContext == null) return;
    _pendingRoute = null;
    router.go(route);
  }
}
