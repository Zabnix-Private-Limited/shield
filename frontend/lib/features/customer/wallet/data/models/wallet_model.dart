import 'dart:convert';

import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/membership.dart';
import '../../../../../shared/models/wallet.dart';
import '../../domain/entities/wallet_entity.dart';
import 'cash_wallet.dart';
import 'reward_wallet.dart';
import 'transaction_model.dart';

class WalletModel extends CustomerWalletEntity {
  const WalletModel({
    required super.walletId,
    required super.customerId,
    required super.status,
    required super.cashWallet,
    required super.rewardWallet,
    required super.benefitSummary,
    required super.recentTransactions,
    required super.statistics,
    required super.membership,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final recentTransactions = (json['recentTransactions'] as List? ?? const [])
        .map(
          (item) => TransactionModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .cast<WalletTransaction>()
        .toList();
    final membershipPayload = Map<String, dynamic>.from(
      json['membership'] as Map? ?? const {},
    );

    return WalletModel(
      walletId: (json['walletId'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      status: (json['status'] ?? 'ACTIVE').toString(),
      cashWallet: CashWalletModel.fromJson(
        Map<String, dynamic>.from(json['cashWallet'] as Map? ?? const {}),
      ),
      rewardWallet: RewardWalletModel.fromJson(
        Map<String, dynamic>.from(json['rewardPoints'] as Map? ?? const {}),
      ),
      benefitSummary: BenefitSummaryEntity(
        benefitsUsed: _asDouble(
          (json['benefitSummary'] as Map?)?['benefitsUsed'],
        ),
        grantedTotal: _asDouble(
          (json['benefitSummary'] as Map?)?['grantedTotal'],
        ),
        appliedTotal: _asDouble(
          (json['benefitSummary'] as Map?)?['appliedTotal'],
        ),
        hiddenRemaining: _asDouble(
          (json['benefitSummary'] as Map?)?['hiddenRemaining'],
        ),
      ),
      recentTransactions: recentTransactions,
      statistics: WalletStatisticsEntity(
        monthlySpend: _asDouble((json['statistics'] as Map?)?['monthlySpend']),
        rewardCredits: _asDouble((json['statistics'] as Map?)?['rewardCredits']),
        creditAvailable: _asDouble(
          (json['statistics'] as Map?)?['creditAvailable'],
        ),
      ),
      membership: Membership.fromApi(
        customer: _syntheticCustomer((json['customerId'] ?? '').toString()),
        customerPayload: {
          'membership': membershipPayload,
        },
        transactions: recentTransactions,
      ),
    );
  }

  factory WalletModel.fromCache(String source) {
    return WalletModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'walletId': walletId,
      'customerId': customerId,
      'status': status,
      'cashWallet': (cashWallet as CashWalletModel).toJson(),
      'rewardPoints': (rewardWallet as RewardWalletModel).toJson(),
      'benefitSummary': {
        'benefitsUsed': benefitSummary.benefitsUsed,
        'grantedTotal': benefitSummary.grantedTotal,
        'appliedTotal': benefitSummary.appliedTotal,
        'hiddenRemaining': benefitSummary.hiddenRemaining,
      },
      'recentTransactions': recentTransactions
          .map(
            (item) => {
              'id': item.id,
              'uuid': item.uuid,
              'wallet_id': item.walletId,
              'transaction_type': item.transactionType,
              'sub_ledger_type': item.subLedgerType,
              'amount': item.amount,
              'reference_type': item.referenceType,
              'reference_id': item.referenceId,
              'remarks': item.remarks,
              'created_by': item.createdBy,
              'created_at': item.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'statistics': {
        'monthlySpend': statistics.monthlySpend,
        'rewardCredits': statistics.rewardCredits,
        'creditAvailable': statistics.creditAvailable,
      },
      'membership': {
        'id': membership.id,
        'uuid': membership.uuid,
        'membershipNumber': membership.customerCode,
        'status': membership.isActive ? 'ACTIVE' : 'INACTIVE',
        'activationDate': membership.startDate.toIso8601String(),
        'expiryDate': membership.endDate.toIso8601String(),
        'createdAt': membership.createdAt.toIso8601String(),
        'updatedAt': membership.updatedAt.toIso8601String(),
        'membershipType': {
          'name': membership.tierLabel,
        },
      },
    };
  }

  String toCache() => jsonEncode(toJson());

  static double _asDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}

Customer _syntheticCustomer(String customerId) {
  final now = DateTime.now();
  return Customer(
    id: customerId,
    uuid: '',
    customerCode: '',
    aadhaarNumber: '',
    firstName: '',
    lastName: '',
    mobile: '',
    status: 'ACTIVE',
    createdAt: now,
    updatedAt: now,
  );
}
