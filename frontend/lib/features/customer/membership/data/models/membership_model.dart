import 'dart:convert';

import '../../../../../shared/models/membership.dart';

class MembershipModel extends Membership {
  const MembershipModel({
    required super.id,
    required super.uuid,
    required super.customerId,
    required super.tier,
    required super.customerCode,
    required super.startDate,
    required super.endDate,
    required super.isActive,
    required super.totalEarnedCredits,
    required super.totalRedeemedCredits,
    required super.createdAt,
    required super.updatedAt,
    super.cardNumber,
    super.cardQrPayload,
    super.cardStatus,
    super.cardIssuedAt,
    super.membershipStatus,
    this.subscription,
  });

  final MembershipSubscriptionEntitlement? subscription;

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    final membership = Map<String, dynamic>.from(
      json['membership'] as Map? ?? const {},
    );
    if (membership.isEmpty) {
      throw const FormatException('Membership payload missing.');
    }

    final membershipType = Map<String, dynamic>.from(
      membership['membershipType'] as Map? ?? const {},
    );
    final stats = Map<String, dynamic>.from(
      json['membershipStats'] as Map? ?? const {},
    );
    final shieldCard = Map<String, dynamic>.from(
      json['shieldCard'] as Map? ?? const {},
    );
    final subscription = Map<String, dynamic>.from(
      json['subscription'] as Map? ?? const {},
    );
    final tierSource =
        (membershipType['name'] ??
                membershipType['code'] ??
                membership['status'] ??
                '')
            .toString()
            .toLowerCase();
    final createdAt = _parseDate(membership['createdAt']);
    final startDate = _parseDate(
      membership['activationDate'],
      fallback: createdAt,
    );

    return MembershipModel(
      id: (membership['id'] ?? '').toString(),
      uuid: (membership['uuid'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      tier: tierSource.contains('founding')
          ? MembershipTier.foundingMember
          : MembershipTier.standardMember,
      customerCode: (membership['membershipNumber'] ?? '').toString(),
      startDate: startDate,
      endDate: _parseDate(
        membership['expiryDate'],
        fallback: startDate.add(const Duration(days: 365)),
      ),
      isActive:
          (membership['status'] ?? '').toString().toUpperCase() == 'ACTIVE',
      membershipStatus: (membership['status'] ?? 'PENDING').toString(),
      totalEarnedCredits: _asDouble(stats['totalEarnedCredits']),
      totalRedeemedCredits: _asDouble(stats['totalRedeemedCredits']),
      createdAt: createdAt,
      updatedAt: _parseDate(membership['updatedAt'], fallback: createdAt),
      cardNumber: shieldCard['cardNumber']?.toString(),
      cardQrPayload: shieldCard['qrCode']?.toString(),
      cardStatus: shieldCard['status']?.toString(),
      cardIssuedAt: shieldCard['issuedAt'] == null
          ? null
          : _parseDate(shieldCard['issuedAt']),
      subscription: subscription.isEmpty
          ? null
          : MembershipSubscriptionEntitlement.fromJson(subscription),
    );
  }

  factory MembershipModel.fromCache(String source) {
    return MembershipModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'membership': {
        'id': id,
        'uuid': uuid,
        'membershipNumber': customerCode,
        'status': membershipStatus,
        'activationDate': startDate.toIso8601String(),
        'expiryDate': endDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'membershipType': {'name': tierLabel},
      },
      'membershipStats': {
        'totalEarnedCredits': totalEarnedCredits,
        'totalRedeemedCredits': totalRedeemedCredits,
        'availableCredits': totalEarnedCredits - totalRedeemedCredits,
      },
      if (subscription != null) 'subscription': subscription!.toJson(),
      if (cardNumber != null || cardQrPayload != null || cardStatus != null)
        'shieldCard': {
          'cardNumber': cardNumber,
          'qrCode': cardQrPayload,
          'status': cardStatus,
          'issuedAt': cardIssuedAt?.toIso8601String(),
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

  static DateTime _parseDate(dynamic value, {DateTime? fallback}) {
    final parsed = value == null ? null : DateTime.tryParse(value.toString());
    return parsed ?? fallback ?? DateTime.now();
  }
}

class MembershipSubscriptionEntitlement {
  const MembershipSubscriptionEntitlement({
    required this.planName,
    required this.status,
    required this.customerContributionPaise,
    required this.shieldBenefitPaise,
    required this.totalEntitlementPaise,
    this.startsOn,
    this.endsOn,
    this.currentAllocation,
  });

  final String planName;
  final String status;
  final int customerContributionPaise;
  final int shieldBenefitPaise;
  final int totalEntitlementPaise;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final MembershipAllocation? currentAllocation;

  factory MembershipSubscriptionEntitlement.fromJson(
    Map<String, dynamic> json,
  ) {
    final allocation = Map<String, dynamic>.from(
      json['currentAllocation'] as Map? ?? const {},
    );
    return MembershipSubscriptionEntitlement(
      planName: (json['planName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      customerContributionPaise: _asInt(json['customerContributionPaise']),
      shieldBenefitPaise: _asInt(json['shieldBenefitPaise']),
      totalEntitlementPaise: _asInt(json['totalEntitlementPaise']),
      startsOn: _tryParseDate(json['startsOn']),
      endsOn: _tryParseDate(json['endsOn']),
      currentAllocation: allocation.isEmpty
          ? null
          : MembershipAllocation.fromJson(allocation),
    );
  }

  Map<String, dynamic> toJson() => {
    'planName': planName,
    'status': status,
    'customerContributionPaise': customerContributionPaise,
    'shieldBenefitPaise': shieldBenefitPaise,
    'totalEntitlementPaise': totalEntitlementPaise,
    'startsOn': startsOn?.toIso8601String(),
    'endsOn': endsOn?.toIso8601String(),
    if (currentAllocation != null)
      'currentAllocation': currentAllocation!.toJson(),
  };
}

class MembershipAllocation {
  const MembershipAllocation({
    required this.monthStart,
    required this.allocationPaise,
    required this.carryForwardPaise,
    required this.usedPaise,
    required this.remainingPaise,
  });

  final DateTime? monthStart;
  final int allocationPaise;
  final int carryForwardPaise;
  final int usedPaise;
  final int remainingPaise;

  factory MembershipAllocation.fromJson(Map<String, dynamic> json) =>
      MembershipAllocation(
        monthStart: _tryParseDate(json['monthStart']),
        allocationPaise: _asInt(json['allocationPaise']),
        carryForwardPaise: _asInt(json['carryForwardPaise']),
        usedPaise: _asInt(json['usedPaise']),
        remainingPaise: _asInt(json['remainingPaise']),
      );

  Map<String, dynamic> toJson() => {
    'monthStart': monthStart?.toIso8601String(),
    'allocationPaise': allocationPaise,
    'carryForwardPaise': carryForwardPaise,
    'usedPaise': usedPaise,
    'remainingPaise': remainingPaise,
  };
}

int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

DateTime? _tryParseDate(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
