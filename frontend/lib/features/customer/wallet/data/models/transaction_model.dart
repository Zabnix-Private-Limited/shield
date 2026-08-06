import '../../../../../shared/models/wallet.dart';

class TransactionModel extends WalletTransaction {
  const TransactionModel({
    required super.id,
    required super.uuid,
    required super.walletId,
    required super.transactionType,
    required super.ledgerEntryType,
    required super.subLedgerType,
    required super.amount,
    super.referenceType,
    super.referenceId,
    super.remarks,
    super.createdBy,
    super.status,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final base = WalletTransaction.fromJson(json);
    return TransactionModel(
      id: base.id,
      uuid: base.uuid,
      walletId: base.walletId,
      transactionType: base.transactionType,
      ledgerEntryType: base.ledgerEntryType,
      subLedgerType: base.subLedgerType,
      amount: base.amount,
      referenceType: base.referenceType,
      referenceId: base.referenceId,
      remarks: base.remarks,
      createdBy: base.createdBy,
      status: base.status,
      createdAt: base.createdAt,
    );
  }
}
