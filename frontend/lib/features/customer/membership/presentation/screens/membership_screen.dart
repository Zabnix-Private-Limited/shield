import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/membership.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/portal_support.dart';
import '../../../shared/domain/customer_access_state.dart';
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

        final accessState = CustomerAccessState(
          customerStatus: membership.isActive ? 'ACTIVE' : 'PENDING',
          membership: membership,
        );

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          color: AppColors.shieldBlue,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              _MembershipHero(membership: membership, accessState: accessState),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720
                      ? 3
                      : constraints.maxWidth >= 420
                      ? 2
                      : 1;
                  final ratio = columns == 1
                      ? 3.0
                      : columns == 2
                      ? 1.45
                      : 1.6;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: ratio,
                    children: [
                      _MembershipStatCard(
                        label: accessState.serviceAccessEnabled
                            ? 'Total credited'
                            : 'Credits unlock later',
                        value:
                            '₹${membership.totalEarnedCredits.toStringAsFixed(0)}',
                        note: accessState.serviceAccessEnabled
                            ? 'Ledger-backed wallet credits'
                            : 'No customer credit is exposed before card issue',
                        color: AppColors.shieldGreen,
                        icon: Icons.arrow_downward_rounded,
                      ),
                      _MembershipStatCard(
                        label: accessState.serviceAccessEnabled
                            ? 'Total used'
                            : 'Service access',
                        value: accessState.serviceAccessEnabled
                            ? '₹${membership.totalRedeemedCredits.toStringAsFixed(0)}'
                            : 'Pending',
                        note: accessState.serviceAccessEnabled
                            ? 'Redeemed across care services'
                            : 'Admin or agent approval is still required',
                        color: AppColors.shieldBlue,
                        icon: Icons.local_hospital_outlined,
                      ),
                      _MembershipStatCard(
                        label: accessState.serviceAccessEnabled
                            ? 'Available now'
                            : 'Card issuance',
                        value: accessState.serviceAccessEnabled
                            ? '₹${(membership.totalEarnedCredits - membership.totalRedeemedCredits).toStringAsFixed(0)}'
                            : 'Awaiting',
                        note: accessState.serviceAccessEnabled
                            ? 'Computed from live customer ledger'
                            : 'SHIELD card is issued by admin or agent team',
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
              ..._tierBenefits(membership.tier, accessState).map(
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
                  subtitle: accessState.serviceAccessEnabled
                      ? 'This customer membership is active and card-backed.'
                      : 'The customer registration is complete, but SHIELD membership issuance is still pending.',
                  meta: accessState.serviceAccessEnabled
                      ? membership.customerCode
                      : (membership.customerCode.isNotEmpty
                            ? membership.customerCode
                            : 'Awaiting SHIELD card'),
                  status: accessState.heroStatusLabel,
                  highlights: [
                    accessState.serviceAccessEnabled
                        ? 'Tier: ${membership.tierLabel}'
                        : 'The digital card is not generated at sign-up.',
                    accessState.serviceAccessEnabled
                        ? 'Valid until ${DateFormat('dd MMM yyyy').format(membership.endDate)}'
                        : 'Admin or SHIELD agent approval is required before services unlock.',
                    accessState.serviceAccessEnabled
                        ? 'Available credits stay derived from live customer ledger totals.'
                        : 'Customers can browse the app and loaded products while they wait.',
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accessState.serviceAccessEnabled
                          ? 'Membership card details'
                          : 'Membership approval details',
                      style: AppTypography.h5,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      accessState.serviceAccessEnabled
                          ? 'View how the customer card, validity period, and wallet-linked credit totals are being interpreted.'
                          : 'Review the pending state before the SHIELD card is issued.',
                      style: AppTypography.small.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _MembershipActions(
                membership: membership,
                accessState: accessState,
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _tierBenefits(
    MembershipTier tier,
    CustomerAccessState accessState,
  ) {
    if (!accessState.serviceAccessEnabled) {
      return const [
        'Your profile is created, but the SHIELD membership card has not been issued yet.',
        'Admin or agent approval is required before doctor, lab, homecare, and other member services unlock.',
        'You can still browse the customer app and purchase loaded products once they are listed.',
        'Wallet-linked benefits stay hidden until the issued card becomes active.',
      ];
    }
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
  const _MembershipHero({required this.membership, required this.accessState});

  final Membership membership;
  final CustomerAccessState accessState;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: accessState.serviceAccessEnabled
              ? switch (membership.tier) {
                  MembershipTier.foundingMember => const [
                    AppColors.shieldBlue,
                    AppColors.shieldNavy,
                  ],
                  MembershipTier.standardMember => const [
                    AppColors.shieldGreen,
                    AppColors.shieldBlue,
                  ],
                }
              : const [AppColors.warning, AppColors.shieldBlue],
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
                  accessState.heroStatusLabel,
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
            accessState.serviceAccessEnabled
                ? membership.tierLabel
                : 'Registration received',
            style: AppTypography.h2.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            accessState.membershipSupportingText,
            style: AppTypography.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (accessState.serviceAccessEnabled) ...[
                _HeroChip(
                  label: 'Valid from',
                  value: DateFormat('dd MMM yyyy').format(membership.startDate),
                ),
                _HeroChip(
                  label: 'Valid until',
                  value: DateFormat('dd MMM yyyy').format(membership.endDate),
                ),
              ] else ...const [
                _HeroChip(label: 'Stage', value: 'Profile created'),
                _HeroChip(label: 'Next step', value: 'Await card issue'),
              ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.shieldNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
  const _MembershipActions({
    required this.membership,
    required this.accessState,
  });

  final Membership membership;
  final CustomerAccessState accessState;

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
            action(
              accessState.serviceAccessEnabled
                  ? 'Open wallet'
                  : 'Browse products',
              () => context.go(
                accessState.serviceAccessEnabled
                    ? '/portal/customer/wallet'
                    : '/portal/customer/services',
              ),
            ),
            action(
              accessState.serviceAccessEnabled
                  ? 'Open profile'
                  : 'Complete profile',
              () => context.go('/portal/customer/profile'),
            ),
            action(
              accessState.serviceAccessEnabled
                  ? 'Renewal guidance'
                  : 'Approval guidance',
              () => showPortalDetailsSheet(
                context,
                title: accessState.serviceAccessEnabled
                    ? 'Renewal guidance'
                    : 'Approval guidance',
                subtitle: accessState.serviceAccessEnabled
                    ? 'Renewal flow can now build on this dedicated membership slice without adding more customer logic back into the shared portal shell.'
                    : 'SHIELD cards are issued by admin or agent operations after registration review.',
                meta: accessState.serviceAccessEnabled
                    ? membership.customerCode
                    : (membership.customerCode.isNotEmpty
                          ? membership.customerCode
                          : 'Awaiting SHIELD card'),
                status: accessState.heroStatusLabel,
                highlights: accessState.serviceAccessEnabled
                    ? const [
                        'Membership routing now stays isolated to the customer slice.',
                        'Future renewal actions can be added here once backend workflow APIs are ready.',
                      ]
                    : const [
                        'Sign-up does not generate a card immediately.',
                        'Customers can browse the app but cannot use member services before issuance.',
                      ],
              ),
              full: true,
            ),
            if (!accessState.serviceAccessEnabled)
              action(
                'Membership status',
                () => context.go('/portal/customer/settings'),
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
