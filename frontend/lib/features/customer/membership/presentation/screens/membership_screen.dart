import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/membership.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/portal_support.dart';
import '../../../../customer/shared/widgets/error_card.dart';
import '../controllers/membership_controller.dart';

class CustomerMembershipScreen extends StatefulWidget {
  const CustomerMembershipScreen({super.key});

  @override
  State<CustomerMembershipScreen> createState() =>
      _CustomerMembershipScreenState();
}

class _CustomerMembershipScreenState extends State<CustomerMembershipScreen> {
  late final MembershipController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MembershipController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading && !_controller.hasData) {
          return const _MembershipLoadingView();
        }

        if (_controller.error != null && !_controller.hasData) {
          return ErrorCard(
            title: 'Membership unavailable',
            message:
                'The customer membership card could not be loaded from the backend.',
            onRetry: _controller.load,
          );
        }

        final membership = _controller.membership;
        if (membership == null) {
          return ErrorCard(
            title: 'Membership unavailable',
            message: 'No membership data is available right now.',
            onRetry: _controller.load,
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          color: AppColors.shieldBlue,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              _MembershipHero(membership: membership),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720
                      ? 3
                      : constraints.maxWidth >= 420
                      ? 2
                      : 1;
                  final ratio = columns == 1 ? 3.3 : 2.2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: ratio,
                    children: [
                      _MembershipStatCard(
                        label: 'Total credited',
                        value:
                            '₹${membership.totalEarnedCredits.toStringAsFixed(0)}',
                        note: 'Ledger-backed wallet credits',
                        color: AppColors.shieldGreen,
                        icon: Icons.arrow_downward_rounded,
                      ),
                      _MembershipStatCard(
                        label: 'Total used',
                        value:
                            '₹${membership.totalRedeemedCredits.toStringAsFixed(0)}',
                        note: 'Redeemed across care services',
                        color: AppColors.shieldBlue,
                        icon: Icons.local_hospital_outlined,
                      ),
                      _MembershipStatCard(
                        label: 'Available now',
                        value:
                            '₹${(membership.totalEarnedCredits - membership.totalRedeemedCredits).toStringAsFixed(0)}',
                        note: 'Computed from live customer ledger',
                        color: AppColors.shieldNavy,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Benefits', style: AppTypography.h4),
              const SizedBox(height: 12),
              ..._tierBenefits(membership.tier).map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
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
                          child: Text(benefit, style: AppTypography.body),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => showPortalDetailsSheet(
                  context,
                  title: 'Membership details',
                  subtitle:
                      'This customer card now reads from the dedicated backend membership bundle instead of rebuilding from dummy fallback state.',
                  meta: membership.customerCode,
                  status: membership.isActive ? 'ACTIVE' : 'INACTIVE',
                  highlights: [
                    'Tier: ${membership.tierLabel}',
                    'Valid until ${DateFormat('dd MMM yyyy').format(membership.endDate)}',
                    'Available credits stay derived from live customer ledger totals.',
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Membership card details', style: AppTypography.h5),
                    const SizedBox(height: 6),
                    Text(
                      'View how the customer card, validity period, and wallet-linked credit totals are being interpreted.',
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _MembershipActions(membership: membership),
            ],
          ),
        );
      },
    );
  }

  List<String> _tierBenefits(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.foundingMember:
        return const [
          'Digital privilege card with branch-ready verification.',
          'Founding-member wallet benefits across SHIELD care touchpoints.',
          'Priority support for onboarding, renewals, and membership exceptions.',
          'Cross-service access for pharmacy, clinic, diagnostics, and follow-ups.',
        ];
      case MembershipTier.standardMember:
        return const [
          'Digital membership card with wallet-linked service access.',
          'Eligibility for supported SHIELD pharmacy and care benefits.',
          'Notifications for appointments, documents, and service updates.',
          'Branch-aware support for active customer membership usage.',
        ];
    }
  }
}

class _MembershipHero extends StatelessWidget {
  const _MembershipHero({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: switch (membership.tier) {
            MembershipTier.foundingMember => const [
              AppColors.shieldBlue,
              AppColors.shieldNavy,
            ],
            MembershipTier.standardMember => const [
              AppColors.shieldGreen,
              AppColors.shieldBlue,
            ],
          },
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SHIELD membership',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  membership.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            membership.tierLabel,
            style: AppTypography.h2.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            membership.customerCode,
            style: AppTypography.body.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                label: 'Valid from',
                value: DateFormat('dd MMM yyyy').format(membership.startDate),
              ),
              _HeroChip(
                label: 'Valid until',
                value: DateFormat('dd MMM yyyy').format(membership.endDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.tiny.copyWith(
              color: AppColors.white.withValues(alpha: 0.76),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipStatCard extends StatelessWidget {
  const _MembershipStatCard({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String note;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.shieldNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  style: AppTypography.small.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipActions extends StatelessWidget {
  const _MembershipActions({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleWidth = constraints.maxWidth;
        final twoColumnWidth = constraints.maxWidth >= 280
            ? (constraints.maxWidth - 12) / 2
            : singleWidth;

        Widget action(String label, VoidCallback onTap, {bool full = false}) {
          return SizedBox(
            width: full ? singleWidth : twoColumnWidth,
            child: Material(
              color: AppColors.shieldBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.small.copyWith(
                      color: AppColors.shieldBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            action('Open wallet', () => context.go('/portal/customer/wallet')),
            action(
              'Open profile',
              () => context.go('/portal/customer/profile'),
            ),
            action(
              'Renewal guidance',
              () => showPortalDetailsSheet(
                context,
                title: 'Renewal guidance',
                subtitle:
                    'Renewal flow can now build on this dedicated membership slice without adding more customer logic back into the shared portal shell.',
                meta: membership.customerCode,
                status: membership.isActive ? 'ACTIVE' : 'INACTIVE',
                highlights: const [
                  'Membership routing now stays isolated to the customer slice.',
                  'Future renewal actions can be added here once backend workflow APIs are ready.',
                ],
              ),
              full: true,
            ),
          ],
        );
      },
    );
  }
}

class _MembershipLoadingView extends StatelessWidget {
  const _MembershipLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
