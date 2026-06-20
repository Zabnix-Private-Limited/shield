import 'package:equatable/equatable.dart';

enum MembershipTier {
  bronze,
  silver,
  gold,
  platinum,
}

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
  tier: MembershipTier.silver,
  customerCode: 'SHLD-2024-123456',
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2025, 1, 1),
  isActive: true,
  totalEarnedCredits: 2500,
  totalRedeemedCredits: 1000,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime.now(),
);
