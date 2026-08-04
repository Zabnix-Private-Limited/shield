import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/wallet/presentation/widgets/transaction_tile.dart';
import 'package:shield/shared/models/wallet.dart';

void main() {
  testWidgets('shows normalized earned reward points as a credit', (
    tester,
  ) async {
    final transaction = WalletTransaction.fromJson(const {
      'id': 'reward-1',
      'wallet_id': 'wallet-1',
      'transaction_type': 'EARNED',
      'sub_ledger_type': 'REWARD_POINTS',
      'amount': 25,
      'remarks': 'Referral reward',
      'created_at': '2026-08-04T00:00:00.000Z',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TransactionTile(transaction: transaction)),
      ),
    );

    expect(find.textContaining('+₹25'), findsOneWidget);
    expect(find.text('Reward points'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
  });
}
