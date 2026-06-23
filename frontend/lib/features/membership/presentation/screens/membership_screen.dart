import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/membership.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/demo_support.dart';
import '../../../../shared/services/api_service.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  late Future<Membership> _membershipFuture;

  @override
  void initState() {
    super.initState();
    _loadMembership();
  }

  void _loadMembership() {
    _membershipFuture = ApiService.getCustomerMembership('1');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Membership'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            onPressed: () {
              context.go('/workspace/customer/membership');
            },
          ),
        ],
      ),
      body: FutureBuilder<Membership>(
        future: _membershipFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.shieldBlue,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load membership details',
                      style: AppTypography.h5,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: AppTypography.body.copyWith(color: AppColors.gray),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadMembership();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text('No membership details found'),
            );
          }

          final membership = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadMembership();
              });
              await _membershipFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                        colors: _getTierColors(membership.tier),
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
                              _getTierName(membership.tier),
                              style: AppTypography.body.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          membership.customerCode,
                          style: AppTypography.h4.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          membership.tier == MembershipTier.foundingMember
                              ? 'Founding privileges with QR-ready digital card access'
                              : 'Standard privileges with digital card access',
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
                                  '${membership.startDate.day}/${membership.startDate.month}/${membership.startDate.year}',
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
                                  '${membership.endDate.day}/${membership.endDate.month}/${membership.endDate.year}',
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
                                    '₹${membership.totalEarnedCredits.toStringAsFixed(0)}',
                                color: AppColors.shieldGreen,
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppColors.divider),
                            Expanded(
                              child: _StatItem(
                                label: 'Total Redeemed',
                                value:
                                    '₹${membership.totalRedeemedCredits.toStringAsFixed(0)}',
                                color: AppColors.shieldBlue,
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppColors.divider),
                            Expanded(
                              child: _StatItem(
                                label: 'Available',
                                value:
                                    '₹${(membership.totalEarnedCredits - membership.totalRedeemedCredits).toStringAsFixed(0)}',
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
                  ..._getTierBenefits(membership.tier).map((benefit) {
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
                        title: 'Membership details',
                        subtitle:
                            'This view displays your live SHIELD membership card, tier privileges, and real-time ledger-calculated credits.',
                        meta: membership.customerCode,
                        status: membership.isActive ? 'Active' : 'Inactive',
                        highlights: [
                          'Membership type: ${_getTierName(membership.tier)}',
                          'Valid until ${membership.endDate.day}/${membership.endDate.month}/${membership.endDate.year}',
                          'Available credits are computed dynamically from your wallet transactions ledger.',
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
        },
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
