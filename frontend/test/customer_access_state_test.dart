import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/shared/domain/customer_access_state.dart';
import 'package:shield/shared/models/membership.dart';

Membership _membership({String? cardStatus}) => Membership(
  id: 'membership-1',
  uuid: 'membership-uuid',
  customerId: 'customer-1',
  tier: MembershipTier.foundingMember,
  customerCode: 'SHLD-2026-931713',
  startDate: DateTime(2026, 8, 11),
  endDate: DateTime(2027, 8, 11),
  isActive: true,
  totalEarnedCredits: 11900,
  totalRedeemedCredits: 1550,
  createdAt: DateTime(2026, 8, 11),
  updatedAt: DateTime(2026, 8, 11),
  cardStatus: cardStatus,
  membershipStatus: 'ACTIVE',
);

void main() {
  group('CustomerAccessState', () {
    test('does not mistake an active membership number for an issued card', () {
      final state = CustomerAccessState(
        customerStatus: 'ACTIVE',
        membership: _membership(),
      );

      expect(state.serviceAccessEnabled, isFalse);
      expect(state.heroStatusLabel, 'CARD PENDING');
      expect(state.membershipHeadline, 'Membership active');
    });

    test('enables care access only for issued or active cards', () {
      for (final status in ['ISSUED', 'ACTIVE']) {
        final state = CustomerAccessState(
          customerStatus: 'ACTIVE',
          membership: _membership(cardStatus: status),
        );
        expect(state.serviceAccessEnabled, isTrue, reason: status);
      }
    });
  });
}
