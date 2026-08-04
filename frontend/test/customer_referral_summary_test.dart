import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/referrals/domain/customer_referral_summary.dart';

void main() {
  test('maps backend referral status history without inventing rewards', () {
    final summary = CustomerReferralSummary.fromJson({
      'referralCode': 'SHIELD-REF-42',
      'directReferrals': 2,
      'totalReferrals': 3,
      'availablePoints': 18,
      'history': [
        {
          'status': 'QUALIFIED',
          'rewardPoints': 10,
          'createdAt': '2026-08-04T10:00:00.000Z',
        },
      ],
    });

    expect(summary.referralCode, 'SHIELD-REF-42');
    expect(summary.directReferrals, 2);
    expect(summary.events.single.status, 'QUALIFIED');
    expect(summary.events.single.rewardPoints, 10);
  });
}
