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

  @override
  List<Object?> get props => [id, uuid, customerId, status, createdAt];
}
