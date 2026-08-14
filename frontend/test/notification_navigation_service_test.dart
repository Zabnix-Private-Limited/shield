import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/services/notification_navigation_service.dart';

void main() {
  group('NotificationNavigationService.resolveCustomerRoute', () {
    test('accepts an allowed customer section target', () {
      expect(NotificationNavigationService.resolveCustomerRoute({'section': 'wallet'}), '/portal/customer/wallet');
    });

    test('rejects an arbitrary route and safely opens notifications', () {
      expect(NotificationNavigationService.resolveCustomerRoute({'route': '/portal/admin/audit'}), '/portal/customer/notifications');
    });

    test('uses the notification center for a missing or unsupported target', () {
      expect(NotificationNavigationService.resolveCustomerRoute({'section': 'unknown'}), '/portal/customer/notifications');
    });
  });
}
