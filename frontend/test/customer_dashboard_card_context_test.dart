import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/dashboard/data/models/dashboard_model.dart';
import 'package:shield/features/customer/dashboard/domain/entities/dashboard_entity.dart';
import 'package:shield/features/customer/shared/domain/customer_access_state.dart';
import 'package:shield/features/customer/dashboard/presentation/widgets/greeting_header.dart';

void main() {
  test(
    'preserves the dashboard shield-card state for customer entitlement UI',
    () {
      final dashboard = DashboardModel.fromJson({
        'customer': {
          'id': '1',
          'uuid': 'customer-uuid',
          'customerCode': 'CUST-931713',
          'firstName': 'Kannan',
          'lastName': '',
          'mobile': '+917034479800',
          'status': 'ACTIVE',
          'createdAt': '2026-08-11T00:00:00.000Z',
          'updatedAt': '2026-08-11T00:00:00.000Z',
        },
        'membership': {
          'id': '1',
          'uuid': 'membership-uuid',
          'membershipNumber': 'SHLD-2026-931713',
          'status': 'ACTIVE',
          'activationDate': '2026-08-11T00:00:00.000Z',
          'expiryDate': '2027-08-11T00:00:00.000Z',
          'createdAt': '2026-08-11T00:00:00.000Z',
          'updatedAt': '2026-08-11T00:00:00.000Z',
          'membershipType': {'name': 'Founding Member'},
        },
        'shieldCard': {'status': 'NOT_ISSUED'},
        'wallet': {},
        'appointments': [],
        'notifications': [],
        'recentActivity': [],
        'documents': [],
        'banners': [],
        'quickActions': [],
        'services': [],
      });

      final access = CustomerAccessState(
        customer: dashboard.customer,
        customerStatus: dashboard.customer.status,
        membership: dashboard.membership,
      );

      expect(dashboard.membership?.cardStatus, 'NOT_ISSUED');
      expect(access.serviceAccessEnabled, isFalse);
      expect(access.membershipHeadline, 'Membership active');
    },
  );

  test(
    'keeps a null backend membership null and does not cache fabricated details',
    () {
      final dashboard = DashboardModel.fromJson({
        'customer': {
          'id': '1',
          'uuid': 'customer-uuid',
          'customerCode': 'CUST-1',
          'firstName': 'Kannan',
          'mobile': '+917034479800',
          'status': 'ACTIVE',
          'createdAt': '2026-08-11T00:00:00.000Z',
          'updatedAt': '2026-08-11T00:00:00.000Z',
        },
        'membership': null,
        'membershipApplication': null,
        'wallet': {},
        'appointments': [],
        'notifications': [],
        'recentActivity': [],
        'documents': [],
        'banners': [],
        'quickActions': [],
        'services': [],
      });

      expect(dashboard.membership, isNull);
      final restored = DashboardModel.fromCache(dashboard.toCache());
      expect(restored.membership, isNull);
    },
  );

  test(
    'resolves application states without inferring membership or card data',
    () {
      final pending = MembershipApplicationEntity(
        id: '1',
        reference: 'MAP-1',
        status: 'PENDING',
        submittedAt: DateTime(2026),
      );
      final rejected = MembershipApplicationEntity(
        id: '2',
        reference: 'MAP-2',
        status: 'REJECTED',
        submittedAt: DateTime(2026),
      );
      expect(
        resolveMembershipDashboardState(membership: null, application: null),
        MembershipDashboardState.noApplication,
      );
      expect(
        resolveMembershipDashboardState(membership: null, application: pending),
        MembershipDashboardState.applicationPending,
      );
      expect(
        resolveMembershipDashboardState(
          membership: null,
          application: rejected,
        ),
        MembershipDashboardState.applicationRejected,
      );
    },
  );
}
