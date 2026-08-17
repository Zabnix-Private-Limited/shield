import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/wallet/presentation/widgets/transaction_list.dart';
import 'package:shield/shared/models/wallet.dart';

WalletTransaction _transaction(int index) => WalletTransaction(
  id: '$index',
  uuid: 'txn-$index',
  walletId: 'wallet-1',
  transactionType: 'CREDIT',
  ledgerEntryType: 'CASH',
  amount: index.toDouble(),
  remarks: 'Transaction $index',
  createdAt: DateTime.utc(2026, 8, 4),
);

void main() {
  testWidgets('renders the requested wallet transaction window', (
    tester,
  ) async {
    final transactions = List.generate(7, _transaction);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TransactionList(transactions: transactions, maxItems: 6),
          ),
        ),
      ),
    );

    expect(find.text('Transaction 6'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TransactionList(transactions: transactions, maxItems: null),
          ),
        ),
      ),
    );

    expect(find.text('Transaction 6'), findsOneWidget);
  });
}
