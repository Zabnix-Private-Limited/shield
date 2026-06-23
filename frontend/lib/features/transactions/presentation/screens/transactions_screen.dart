import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/wallet.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/demo_support.dart';
import '../../../../shared/services/api_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late Future<Map<String, dynamic>> _walletProfileFuture;
  late Future<List<WalletTransaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    setState(() {
      _walletProfileFuture = ApiService.getWalletProfile('1');
      _transactionsFuture = _walletProfileFuture.then((profile) {
        final walletId = profile['walletId'].toString();
        return ApiService.getWalletTransactions(walletId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_walletProfileFuture, _transactionsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Failed to load transactions', style: AppTypography.h3),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: AppTypography.body),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Retry',
                      onPressed: _loadTransactions,
                    ),
                  ],
                ),
              ),
            );
          }

          final txns = snapshot.data![1] as List<WalletTransaction>;

          if (txns.isEmpty) {
            return DemoEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions available',
              description:
                  'Wallet credits, debits, and promotional entries will appear here once the member starts using the SHIELD wallet.',
              actionText: 'Open Wallet',
              onAction: () => context.go('/workspace/customer/wallet'),
            );
          }

          // Compute postBalances
          final chronologicalTxns = txns.reversed.toList();
          final Map<String, double> postBalances = {};
          double runningBalance = 0.0;
          for (final t in chronologicalTxns) {
            runningBalance += t.transactionType == 'CREDIT' ? t.amount : -t.amount;
            postBalances[t.id] = runningBalance;
          }

          return RefreshIndicator(
            onRefresh: () async => _loadTransactions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: txns.length,
              itemBuilder: (context, index) {
                final txn = txns[index];
                final postBal = postBalances[txn.id] ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      showDemoDetailsSheet(
                        context,
                        title: txn.remarks ?? 'Transaction',
                        subtitle:
                            'A ${txn.transactionType.toLowerCase()} of ₹${txn.amount.toStringAsFixed(2)} is listed with its running wallet balance.',
                        meta: 'Transaction ID ${txn.id}',
                        status: txn.transactionType,
                        highlights: [
                          'Created by: ${txn.createdBy ?? 'System'}',
                          'Balance after this entry: ₹${postBal.toStringAsFixed(2)}',
                          if (txn.referenceType != null)
                            'Reference: ${txn.referenceType} ${txn.referenceId ?? ''}'
                                .trim(),
                        ],
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: txn.transactionType == 'CREDIT'
                                ? AppColors.shieldGreen.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            txn.transactionType == 'CREDIT'
                                ? Icons.add
                                : Icons.remove,
                            color: txn.transactionType == 'CREDIT'
                                ? AppColors.shieldGreen
                                : AppColors.error,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                txn.remarks ?? 'Transaction',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year} • ${txn.createdAt.hour}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
                                style: AppTypography.tiny.copyWith(
                                  color: AppColors.gray,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Transaction ID: ${txn.id}',
                                style: AppTypography.tiny.copyWith(
                                  color: AppColors.gray.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${txn.transactionType == 'CREDIT' ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                              style: AppTypography.h4.copyWith(
                                color: txn.transactionType == 'CREDIT'
                                    ? AppColors.shieldGreen
                                    : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Balance: ₹${postBal.toStringAsFixed(2)}',
                              style: AppTypography.tiny.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
