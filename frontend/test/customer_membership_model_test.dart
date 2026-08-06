import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/membership/data/models/membership_model.dart';
import 'package:shield/features/customer/shared/domain/customer_access_state.dart';

void main() {
  test('keeps issued privilege-card fields from the membership bundle', () {
    final membership = MembershipModel.fromJson(const {
      'customerId': '42',
      'membership': {
        'id': '7',
        'uuid': 'member-7',
        'membershipNumber': 'SHLD-00042',
        'status': 'ACTIVE',
        'activationDate': '2026-01-01T00:00:00.000Z',
        'expiryDate': '2027-01-01T00:00:00.000Z',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'membershipType': {'name': 'Founding Member'},
      },
      'membershipStats': {
        'totalEarnedCredits': 100,
        'totalRedeemedCredits': 40,
      },
      'subscription': {
        'planName': 'SHIELD Privilege Plan',
        'status': 'ACTIVE',
        'customerContributionPaise': 1000000,
        'shieldBenefitPaise': 100000,
        'totalEntitlementPaise': 1100000,
        'currentAllocation': {
          'monthStart': '2026-08-01T00:00:00.000Z',
          'allocationPaise': 100000,
          'carryForwardPaise': 1000,
          'usedPaise': 2000,
          'remainingPaise': 99000,
        },
      },
      'shieldCard': {
        'cardNumber': 'SHLD-CARD-00042',
        'qrCode': 'server-issued-qr-payload',
        'status': 'ACTIVE',
        'issuedAt': '2026-01-02T00:00:00.000Z',
      },
    });

    expect(membership.customerCode, 'SHLD-00042');
    expect(membership.cardNumber, 'SHLD-CARD-00042');
    expect(membership.cardQrPayload, 'server-issued-qr-payload');
    expect(membership.cardStatus, 'ACTIVE');
    expect(membership.subscription?.shieldBenefitPaise, 100000);
    expect(membership.subscription?.currentAllocation?.remainingPaise, 99000);
    expect(
      CustomerAccessState(
        customerStatus: 'ACTIVE',
        membership: membership,
      ).serviceAccessEnabled,
      isTrue,
    );
  });
}
