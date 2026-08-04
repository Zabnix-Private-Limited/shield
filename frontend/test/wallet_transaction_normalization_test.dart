import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/models/wallet.dart';

void main() {
  test(
    'normalizes backend reward-point ledger entries for customer filtering',
    () {
      final transaction = WalletTransaction.fromJson(const {
        'id': '1',
        'wallet_id': '2',
        'transaction_type': 'EARNED',
        'sub_ledger_type': 'REWARD_POINTS',
        'amount': 25,
        'created_at': '2026-08-04T00:00:00.000Z',
      });

      expect(transaction.subLedgerType, 'POINTS');
      expect(transaction.isCredit, isTrue);
    },
  );

  test('keeps SHIELD Benefit separate from cash', () {
    final transaction = WalletTransaction.fromJson(const {
      'id': '2',
      'wallet_id': '2',
      'transaction_type': 'GRANT',
      'sub_ledger_type': 'SHIELD_BENEFIT',
      'amount': 100,
      'created_at': '2026-08-04T00:00:00.000Z',
    });

    expect(transaction.subLedgerType, 'BENEFIT');
    expect(transaction.subLedgerType, isNot('CASH'));
  });
}
