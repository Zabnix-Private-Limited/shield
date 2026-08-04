import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/wallet/data/models/wallet_model.dart';
import 'package:shield/features/customer/wallet/data/repositories/wallet_repository.dart';
import 'package:shield/features/customer/wallet/presentation/controllers/wallet_controller.dart';
import 'package:shield/features/customer/wallet/presentation/screens/wallet_screen.dart';
import 'package:shield/shared/models/customer.dart';

void main() {
  testWidgets(
    'uses the wallet membership to unlock an active customer wallet',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerWalletScreen(
              controller: WalletController(
                customerId: '42',
                repository: _WalletTestRepository(_wallet()),
              ),
              loadCustomer: () async => _customer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wallet overview'), findsOneWidget);
      expect(find.text('Wallet pending activation'), findsNothing);
      expect(find.textContaining('₹250'), findsWidgets);
      expect(find.text('SHIELD Benefit grant'), findsNothing);
    },
  );
}

class _WalletTestRepository extends WalletRepository {
  _WalletTestRepository(this.value);

  final WalletModel value;

  @override
  Future<WalletModel?> loadCachedWallet(String customerId) async => null;

  @override
  Future<WalletModel> loadWallet(String customerId) async => value;
}

WalletModel _wallet() => WalletModel.fromJson(const {
  'walletId': '9',
  'customerId': '42',
  'status': 'ACTIVE',
  'cashWallet': {'available': 250, 'credited': 300, 'debited': 50},
  'rewardPoints': {'available': 15, 'earned': 20, 'redeemed': 5},
  'benefitSummary': {
    'benefitsUsed': 0,
    'grantedTotal': 1000,
    'appliedTotal': 0,
    'hiddenRemaining': 1000,
  },
  'recentTransactions': [
    {
      'id': 'benefit-1',
      'wallet_id': '9',
      'transaction_type': 'GRANT',
      'sub_ledger_type': 'SHIELD_BENEFIT',
      'amount': 1000,
      'remarks': 'SHIELD Benefit grant',
      'created_at': '2026-08-04T00:00:00.000Z',
    },
  ],
  'statistics': {
    'monthlySpend': 50,
    'rewardCredits': 20,
    'creditAvailable': 250,
  },
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
});

Customer _customer() => Customer.fromJson(const {
  'id': '42',
  'uuid': 'customer-42',
  'customerCode': 'SHLD-00042',
  'firstName': 'Rahul',
  'lastName': 'Muraleedharan',
  'mobile': '9876543210',
  'status': 'ACTIVE',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
});
