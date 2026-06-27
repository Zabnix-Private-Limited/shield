import 'package:equatable/equatable.dart';

import 'customer.dart';
import 'wallet.dart';

enum MembershipTier { foundingMember, standardMember }

class Membership extends Equatable {
  final String id;
  final String uuid;
  final String customerId;
  final MembershipTier tier;
  final String customerCode;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final double totalEarnedCredits;
  final double totalRedeemedCredits;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Membership({
    required this.id,
    required this.uuid,
    required this.customerId,
    required this.tier,
    required this.customerCode,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.totalEarnedCredits,
    required this.totalRedeemedCredits,
    required this.createdAt,
    required this.updatedAt,
  });

  String get tierLabel => switch (tier) {
    MembershipTier.foundingMember => 'Founding Member',
    MembershipTier.standardMember => 'Standard Member',
  };

  factory Membership.fromApi({
    required Customer customer,
    required Map<String, dynamic> customerPayload,
    required List<WalletTransaction> transactions,
  }) {
    final membership = customerPayload['membership'] as Map<String, dynamic>?;
    final membershipType =
        membership?['membershipType'] as Map<String, dynamic>?;
    final tierSource =
        (membershipType?['name'] ??
                membershipType?['code'] ??
                membership?['status'] ??
                '')
            .toString()
            .toLowerCase();
    final earned = transactions
        .where((txn) => txn.transactionType.toUpperCase() == 'CREDIT')
        .fold<double>(0, (total, txn) => total + txn.amount);
    final redeemed = transactions
        .where((txn) => txn.transactionType.toUpperCase() != 'CREDIT')
        .fold<double>(0, (total, txn) => total + txn.amount);

    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      return DateTime.tryParse(value.toString()) ?? fallback;
    }

    final createdAt = parseDate(
      membership?['createdAt'] ?? membership?['created_at'],
      customer.createdAt,
    );
    final startDate = parseDate(
      membership?['activationDate'] ?? membership?['activation_date'],
      customer.createdAt,
    );
    final endDate = parseDate(
      membership?['expiryDate'] ?? membership?['expiry_date'],
      startDate.add(const Duration(days: 365)),
    );

    return Membership(
      id: (membership?['id'] ?? customer.id).toString(),
      uuid: (membership?['uuid'] ?? 'membership-${customer.id}').toString(),
      customerId: customer.id,
      tier: tierSource.contains('founding')
          ? MembershipTier.foundingMember
          : MembershipTier.standardMember,
      customerCode:
          (membership?['membershipNumber'] ??
                  membership?['membership_number'] ??
                  customer.customerCode)
              .toString(),
      startDate: startDate,
      endDate: endDate,
      isActive:
          ((membership?['status'] ?? customer.status)
              .toString()
              .toUpperCase()) ==
          'ACTIVE',
      totalEarnedCredits: earned,
      totalRedeemedCredits: redeemed,
      createdAt: createdAt,
      updatedAt: parseDate(
        membership?['updatedAt'] ?? membership?['updated_at'],
        customer.updatedAt,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    customerId,
    tier,
    customerCode,
    startDate,
    endDate,
    isActive,
    totalEarnedCredits,
    totalRedeemedCredits,
    createdAt,
    updatedAt,
  ];
}

final Membership dummyMembership = Membership(
  id: '1',
  uuid: 'membership-001',
  customerId: '1',
  tier: MembershipTier.foundingMember,
  customerCode: 'SHLD-2026-123456',
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2027, 1, 1),
  isActive: true,
  totalEarnedCredits: 2500,
  totalRedeemedCredits: 1000,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 6, 20, 9, 0),
);
