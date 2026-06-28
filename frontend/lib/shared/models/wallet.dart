import 'package:equatable/equatable.dart';

class WalletTransaction extends Equatable {
  final String id;
  final String uuid;
  final String walletId;
  final String transactionType;
  final String subLedgerType; // 'CASH' or 'POINTS'
  final double amount;
  final String? referenceType;
  final String? referenceId;
  final String? remarks;
  final String? createdBy;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.uuid,
    required this.walletId,
    required this.transactionType,
    this.subLedgerType = 'CASH',
    required this.amount,
    this.referenceType,
    this.referenceId,
    this.remarks,
    this.createdBy,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0;
      return double.tryParse(value.toString()) ?? 0;
    }

    String normalizeLedgerType(Map<String, dynamic> source) {
      final rawLedger =
          (source['subLedgerType'] ??
                  source['sub_ledger_type'] ??
                  source['ledger'] ??
                  'CASH')
              .toString()
              .toUpperCase();
      if (rawLedger == 'REWARD_POINTS') {
        return 'POINTS';
      }
      if (rawLedger == 'SHIELD_BENEFIT') {
        return 'BENEFIT';
      }
      return rawLedger;
    }

    String normalizeTransactionType(Map<String, dynamic> source) {
      final rawType =
          (source['transactionType'] ?? source['transaction_type'] ?? 'DEBIT')
              .toString()
              .toUpperCase();
      const creditTypes = {
        'CREDIT',
        'RECHARGE',
        'OPENING_BALANCE',
        'POINT_REDEMPTION_CREDIT',
        'REVERSAL_CREDIT',
        'BONUS',
        'EARNED',
        'REFERRAL_REWARDED',
        'APPROVED_CREDIT',
        'GRANT',
        'PRELOAD',
      };
      return creditTypes.contains(rawType) ? 'CREDIT' : 'DEBIT';
    }

    return WalletTransaction(
      id: json['id'].toString(),
      uuid: (json['uuid'] ?? 'wallet-txn-${json['id']}').toString(),
      walletId:
          (json['walletId'] ?? json['wallet_id'] ?? json['wallet_id_fk'] ?? '')
              .toString(),
      transactionType: normalizeTransactionType(json),
      subLedgerType: normalizeLedgerType(json),
      amount: parseAmount(json['amount']),
      referenceType: (json['referenceType'] ?? json['reference_type'])
          ?.toString(),
      referenceId: (json['referenceId'] ?? json['reference_id'])?.toString(),
      remarks: json['remarks']?.toString(),
      createdBy: (json['createdBy'] ?? json['created_by'])?.toString(),
      createdAt:
          DateTime.tryParse(
            (json['createdAt'] ?? json['created_at']).toString(),
          ) ??
          DateTime.now(),
    );
  }

  bool get isCredit => transactionType.toUpperCase() == 'CREDIT';

  double get signedAmount => isCredit ? amount : -amount;

  double get postBalance {
    double balance = 0;
    for (final txn in dummyTransactions) {
      if (txn.walletId == walletId && txn.subLedgerType == subLedgerType) {
        balance += txn.signedAmount;
      }

      if (txn.id == id) {
        return balance;
      }
    }
    return balance;
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    walletId,
    transactionType,
    subLedgerType,
    amount,
    referenceType,
    referenceId,
    remarks,
    createdBy,
    createdAt,
  ];
}

final List<WalletTransaction> dummyTransactions = [
  WalletTransaction(
    id: '1',
    uuid: 'txn-001',
    walletId: 'wallet-1',
    transactionType: 'CREDIT',
    amount: 5000.00,
    remarks: 'Wallet recharge',
    createdBy: 'user-1',
    createdAt: DateTime(2026, 6, 1, 10, 30),
  ),
  WalletTransaction(
    id: '1p',
    uuid: 'txn-001-points',
    walletId: 'wallet-1',
    transactionType: 'CREDIT',
    subLedgerType: 'POINTS',
    amount: 250.00,
    remarks: 'Referral reward - Fathima Sherin approval',
    createdBy: 'system',
    createdAt: DateTime(2026, 6, 2, 9, 30),
  ),
  WalletTransaction(
    id: '2',
    uuid: 'txn-002',
    walletId: 'wallet-1',
    transactionType: 'DEBIT',
    amount: 1200.00,
    remarks: 'Pharmacy purchase - SHIELD Hyper Pharmacy, Perinthalmanna',
    referenceType: 'PURCHASE',
    referenceId: 'pur-001',
    createdBy: 'pharmacy-1',
    createdAt: DateTime(2026, 6, 3, 14, 15),
  ),
  WalletTransaction(
    id: '3',
    uuid: 'txn-003',
    walletId: 'wallet-1',
    transactionType: 'DEBIT',
    amount: 500.00,
    remarks: 'Consultation fee - Dr. Haneefa, Manjeri',
    referenceType: 'APPOINTMENT',
    referenceId: 'appt-001',
    createdBy: 'clinic-1',
    createdAt: DateTime(2026, 6, 5, 11, 20),
  ),
  WalletTransaction(
    id: '3p',
    uuid: 'txn-003-points',
    walletId: 'wallet-1',
    transactionType: 'DEBIT',
    subLedgerType: 'POINTS',
    amount: 40.00,
    remarks: 'Loyalty points redeemed - Lab discount, Tirur',
    referenceType: 'REWARD_REDEMPTION',
    referenceId: 'rew-001',
    createdBy: 'lab-1',
    createdAt: DateTime(2026, 6, 6, 12, 10),
  ),
  WalletTransaction(
    id: '4',
    uuid: 'txn-004',
    walletId: 'wallet-1',
    transactionType: 'CREDIT',
    amount: 2000.00,
    remarks: 'Bonus credit',
    createdBy: 'admin',
    createdAt: DateTime(2026, 6, 10, 9, 0),
  ),
  WalletTransaction(
    id: '4p',
    uuid: 'txn-004-points',
    walletId: 'wallet-1',
    transactionType: 'CREDIT',
    subLedgerType: 'POINTS',
    amount: 120.00,
    remarks: 'Promotional wellness reward - Preventive camp',
    createdBy: 'admin',
    createdAt: DateTime(2026, 6, 10, 9, 5),
  ),
  WalletTransaction(
    id: '5',
    uuid: 'txn-005',
    walletId: 'wallet-1',
    transactionType: 'DEBIT',
    amount: 350.00,
    remarks: 'Lab test - CBC, Makkaraparamba',
    referenceType: 'PURCHASE',
    referenceId: 'pur-002',
    createdBy: 'lab-1',
    createdAt: DateTime(2026, 6, 12, 16, 45),
  ),
  WalletTransaction(
    id: '6p',
    uuid: 'txn-006-points',
    walletId: 'wallet-1',
    transactionType: 'CREDIT',
    subLedgerType: 'POINTS',
    amount: 60.00,
    remarks: 'Loyalty reward - Hyper Pharmacy repeat purchase',
    createdBy: 'pharmacy-1',
    createdAt: DateTime(2026, 6, 18, 18, 20),
  ),
];

class Wallet extends Equatable {
  final String id;
  final String uuid;
  final String customerId;
  final String status;
  final DateTime createdAt;

  const Wallet({
    required this.id,
    required this.uuid,
    required this.customerId,
    required this.status,
    required this.createdAt,
  });

  double get currentBalance {
    double balance = 0;
    for (final txn in dummyTransactions) {
      if (txn.walletId == id && txn.subLedgerType == 'CASH') {
        balance += txn.signedAmount;
      }
    }
    return balance;
  }

  @override
  List<Object?> get props => [id, uuid, customerId, status, createdAt];
}

final dummyWallet = Wallet(
  id: 'wallet-1',
  uuid: 'wallet-uuid-001',
  customerId: '1',
  status: 'ACTIVE',
  createdAt: DateTime(2026, 1, 10),
);
