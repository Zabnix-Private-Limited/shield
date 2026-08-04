class CustomerReferralEvent {
  const CustomerReferralEvent({
    required this.status,
    required this.rewardPoints,
    required this.createdAt,
  });

  final String status;
  final num rewardPoints;
  final DateTime? createdAt;

  factory CustomerReferralEvent.fromJson(Map<String, dynamic> json) =>
      CustomerReferralEvent(
        status: json['status']?.toString().trim() ?? '',
        rewardPoints: num.tryParse(json['rewardPoints']?.toString() ?? '') ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

class CustomerReferralSummary {
  const CustomerReferralSummary({
    required this.referralCode,
    required this.directReferrals,
    required this.totalReferrals,
    required this.availablePoints,
    required this.events,
  });

  final String referralCode;
  final int directReferrals;
  final int totalReferrals;
  final num availablePoints;
  final List<CustomerReferralEvent> events;

  factory CustomerReferralSummary.fromJson(Map<String, dynamic> json) {
    final history = json['history'] is List
        ? json['history'] as List
        : const <dynamic>[];
    return CustomerReferralSummary(
      referralCode: json['referralCode']?.toString().trim() ?? '',
      directReferrals:
          int.tryParse(json['directReferrals']?.toString() ?? '') ?? 0,
      totalReferrals:
          int.tryParse(json['totalReferrals']?.toString() ?? '') ?? 0,
      availablePoints:
          num.tryParse(json['availablePoints']?.toString() ?? '') ?? 0,
      events: history
          .whereType<Map>()
          .map(
            (item) =>
                CustomerReferralEvent.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}
