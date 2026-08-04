import 'package:flutter/material.dart';

import '../../../../../shared/models/wallet.dart';
import 'transaction_tile.dart';
import 'wallet_empty_state.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({
    super.key,
    required this.transactions,
    this.maxItems = 6,
  });

  final List<WalletTransaction> transactions;
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const WalletEmptyState();
    }

    return Column(
      children: (maxItems == null ? transactions : transactions.take(maxItems!))
          .map(
            (txn) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TransactionTile(transaction: txn),
            ),
          )
          .toList(),
    );
  }
}
