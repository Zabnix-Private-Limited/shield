import 'package:equatable/equatable.dart';

class WalletTransaction extends Equatable {
  final String id;
  final String uuid;
  final String walletId;
  final String transactionType;
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
    required this.amount,
    this.referenceType,
    this.referenceId,
    this.remarks,
    this.createdBy,
    required this.createdAt,
  });

  double get postBalance {
    double balance = 0;
    for (final txn in dummyTransactions) {
      if (txn.walletId == walletId) {
        balance += txn.transactionType == 'CREDIT' ? txn.amount : -txn.amount;
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
      if (txn.walletId == id) {
        if (txn.transactionType == 'CREDIT') {
          balance += txn.amount;
        } else {
          balance -= txn.amount;
        }
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
