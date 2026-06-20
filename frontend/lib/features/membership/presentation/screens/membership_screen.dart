import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/membership.dart';
import '../../../../shared/widgets/app_card.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Membership'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Membership Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getTierColors(dummyMembership.tier),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SHIELD',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getTierName(dummyMembership.tier),
                        style: AppTypography.body.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    dummyMembership.customerCode,
                    style: AppTypography.h4.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Valid From',
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '${dummyMembership.startDate.day}/${dummyMembership.startDate.month}/${dummyMembership.startDate.year}',
                            style: AppTypography.small.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Valid Until',
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            '${dummyMembership.endDate.day}/${dummyMembership.endDate.month}/${dummyMembership.endDate.year}',
                            style: AppTypography.small.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          label: 'Total Earned',
                          value: '₹${dummyMembership.totalEarnedCredits.toStringAsFixed(0)}',
                          color: AppColors.shieldGreen,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.divider,
                      ),
                      Expanded(
                        child: _StatItem(
                          label: 'Total Redeemed',
                          value: '₹${dummyMembership.totalRedeemedCredits.toStringAsFixed(0)}',
                          color: AppColors.shieldBlue,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.divider,
                      ),
                      Expanded(
                        child: _StatItem(
                          label: 'Available',
                          value: '₹${(dummyMembership.totalEarnedCredits - dummyMembership.totalRedeemedCredits).toStringAsFixed(0)}',
                          color: AppColors.shieldNavy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Benefits
            Text(
              'Benefits',
              style: AppTypography.h5,
            ),
            const SizedBox(height: 12),
            ..._getTierBenefits(dummyMembership.tier).map((benefit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.shieldGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        benefit,
                        style: AppTypography.body,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Color> _getTierColors(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.bronze:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      case MembershipTier.silver:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case MembershipTier.gold:
        return [const Color(0xFFFFD700), const Color(0xFFB8860B)];
      case MembershipTier.platinum:
        return [const Color(0xFFE5E4E2), const Color(0xFF36454F)];
    }
  }

  String _getTierName(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.bronze:
        return 'Bronze';
      case MembershipTier.silver:
        return 'Silver';
      case MembershipTier.gold:
        return 'Gold';
      case MembershipTier.platinum:
        return 'Platinum';
    }
  }

  List<String> _getTierBenefits(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.bronze:
        return [
          '5% cashback on all purchases',
          'Free standard delivery',
          'Priority customer support',
        ];
      case MembershipTier.silver:
        return [
          '7% cashback on all purchases',
          'Free standard delivery',
          'Priority customer support',
          'Early access to sales',
        ];
      case MembershipTier.gold:
        return [
          '10% cashback on all purchases',
          'Free express delivery',
          'Dedicated account manager',
          'Early access to sales',
          'Exclusive offers',
        ];
      case MembershipTier.platinum:
        return [
          '15% cashback on all purchases',
          'Free premium delivery',
          'Dedicated account manager',
          'Early access to sales',
          'Exclusive offers',
          'Free health checkups',
        ];
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h5.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
