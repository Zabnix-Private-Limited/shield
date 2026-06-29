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
  });

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
      totalEarnedCredits: _asDouble(stats['totalEarnedCredits']),
      totalRedeemedCredits: _asDouble(stats['totalRedeemedCredits']),
      createdAt: createdAt,
      updatedAt: _parseDate(membership['updatedAt'], fallback: createdAt),
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
        'status': isActive ? 'ACTIVE' : 'INACTIVE',
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
