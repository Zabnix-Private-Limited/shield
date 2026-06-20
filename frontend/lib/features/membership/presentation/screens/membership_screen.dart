import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/membership.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/demo_support.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Membership'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            onPressed: () {
              context.go('/demo/customer/membership');
            },
          ),
        ],
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
                  const SizedBox(height: 12),
                  Text(
                    'Founding privileges with QR-ready digital card access',
                    style: AppTypography.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.82),
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
                          value:
                              '₹${dummyMembership.totalEarnedCredits.toStringAsFixed(0)}',
                          color: AppColors.shieldGreen,
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(
                        child: _StatItem(
                          label: 'Total Redeemed',
                          value:
                              '₹${dummyMembership.totalRedeemedCredits.toStringAsFixed(0)}',
                          color: AppColors.shieldBlue,
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(
                        child: _StatItem(
                          label: 'Available',
                          value:
                              '₹${(dummyMembership.totalEarnedCredits - dummyMembership.totalRedeemedCredits).toStringAsFixed(0)}',
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
            Text('Benefits', style: AppTypography.h5),
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
                    Expanded(child: Text(benefit, style: AppTypography.body)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            AppCard(
              onTap: () {
                showDemoDetailsSheet(
                  context,
                  title: 'Membership summary',
                  subtitle:
                      'This frontend-only view mirrors the SHIELD membership card, benefits, and renewal story without backend dependencies.',
                  meta: dummyMembership.customerCode,
                  status: dummyMembership.isActive ? 'Active' : 'Inactive',
                  highlights: [
                    'Membership type: ${_getTierName(dummyMembership.tier)}',
                    'Valid until ${dummyMembership.endDate.day}/${dummyMembership.endDate.month}/${dummyMembership.endDate.year}',
                    'The richer role-based membership page is also available from the multi-role demo.',
                  ],
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need the full card demo?',
                          style: AppTypography.h5,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Open the richer customer membership workspace with the digital privilege card and renewal flow.',
                          style: AppTypography.small.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.gray,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getTierColors(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.foundingMember:
        return [AppColors.shieldBlue, AppColors.shieldNavy];
      case MembershipTier.standardMember:
        return [AppColors.shieldGreen, AppColors.shieldBlue];
    }
  }

  String _getTierName(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.foundingMember:
        return 'Founding Member';
      case MembershipTier.standardMember:
        return 'Standard Member';
    }
  }

  List<String> _getTierBenefits(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.foundingMember:
        return [
          'Digital privilege card with QR verification',
          'Founding-member pharmacy and healthcare benefits',
          'Wallet-linked service access across SHIELD partner points',
          'Priority support for onboarding and membership exceptions',
        ];
      case MembershipTier.standardMember:
        return [
          'Digital membership card with branch verification support',
          'Wallet and appointment access across SHIELD services',
          'Notification support for documents, reports, and visits',
          'Eligibility for selected service-linked benefits',
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
          Text(value, style: AppTypography.h5.copyWith(color: color)),
        ],
      ),
    );
  }
}
