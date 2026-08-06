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
import '../../data/models/membership_model.dart';
import '../controllers/membership_controller.dart';

class CustomerMembershipScreen extends StatefulWidget {
  const CustomerMembershipScreen({super.key, this.controller});

  final MembershipController? controller;

  @override
  State<CustomerMembershipScreen> createState() =>
      _CustomerMembershipScreenState();
}

class _CustomerMembershipScreenState extends State<CustomerMembershipScreen> {
  late final MembershipController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? MembershipController();
    _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
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
                            ? 'Cash credited'
                            : 'Credits unlock later',
                        value:
                            '₹${membership.totalEarnedCredits.toStringAsFixed(0)}',
                        note: accessState.serviceAccessEnabled
                            ? 'CASH wallet ledger only'
                            : 'No customer credit is exposed before card issue',
                        color: AppColors.shieldGreen,
                        icon: Icons.arrow_downward_rounded,
                      ),
                      _MembershipStatCard(
                        label: accessState.serviceAccessEnabled
                            ? 'Cash spent'
                            : 'Service access',
                        value: accessState.serviceAccessEnabled
                            ? '₹${membership.totalRedeemedCredits.toStringAsFixed(0)}'
                            : 'Pending',
                        note: accessState.serviceAccessEnabled
                            ? 'CASH wallet ledger only'
                            : 'Admin or agent approval is still required',
                        color: AppColors.shieldBlue,
                        icon: Icons.local_hospital_outlined,
                      ),
                      _MembershipStatCard(
                        label: accessState.serviceAccessEnabled
                            ? 'Cash balance'
                            : 'Card issuance',
                        value: accessState.serviceAccessEnabled
                            ? '₹${(membership.totalEarnedCredits - membership.totalRedeemedCredits).toStringAsFixed(0)}'
                            : 'Awaiting',
                        note: accessState.serviceAccessEnabled
                            ? 'Computed from live CASH ledger'
                            : 'SHIELD card is issued by admin or agent team',
                        color: AppColors.shieldNavy,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _SubscriptionEntitlementCard(
                subscription: membership.subscription,
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.credit_card_off_outlined,
                      color: AppColors.gray,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Use Card status to request or track a physical card. Card history, replacement, lost and damaged-card actions are not available yet.',
                        style: AppTypography.small.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                    ),
                  ],
                ),
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
          'Your membership plan is recorded as Founding Member.',
          'Your issued card status and membership validity are shown above.',
          'Service coverage, exclusions, and annual limits are not in the customer membership contract yet.',
        ];
      case MembershipTier.standardMember:
        return const [
          'Your membership plan is recorded as Standard Member.',
          'Your issued card status and membership validity are shown above.',
          'Service coverage, exclusions, and annual limits are not in the customer membership contract yet.',
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
              _HeroChip(
                label: 'Membership no.',
                value: membership.customerCode.isEmpty
                    ? 'Pending issue'
                    : membership.customerCode,
              ),
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

class _SubscriptionEntitlementCard extends StatelessWidget {
  const _SubscriptionEntitlementCard({required this.subscription});

  final MembershipSubscriptionEntitlement? subscription;

  @override
  Widget build(BuildContext context) {
    final subscription = this.subscription;
    if (subscription == null) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subscription entitlement', style: AppTypography.h5),
                  const SizedBox(height: 4),
                  Text(
                    'There is no current subscription entitlement on this membership.',
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final allocation = subscription.currentAllocation;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: AppColors.shieldBlue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Subscription entitlement',
                  style: AppTypography.h5,
                ),
              ),
              _SubscriptionStatus(status: subscription.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subscription.planName,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 14),
          _EntitlementLine(
            'Your contribution',
            _formatPaise(subscription.customerContributionPaise),
          ),
          _EntitlementLine(
            'SHIELD Benefit',
            _formatPaise(subscription.shieldBenefitPaise),
          ),
          const Divider(height: 22),
          _EntitlementLine(
            'Total entitlement',
            _formatPaise(subscription.totalEntitlementPaise),
            emphasis: true,
          ),
          if (allocation != null) ...[
            const SizedBox(height: 14),
            Text(
              'Current allocation',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            _EntitlementLine(
              'Allocated',
              _formatPaise(allocation.allocationPaise),
            ),
            _EntitlementLine(
              'Carry-forward',
              _formatPaise(allocation.carryForwardPaise),
            ),
            _EntitlementLine('Used', _formatPaise(allocation.usedPaise)),
            _EntitlementLine(
              'Remaining',
              _formatPaise(allocation.remainingPaise),
              emphasis: true,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No allocation is recorded for the current subscription period.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'SHIELD Benefit is a membership entitlement. It is not a CASH wallet balance or reward-point balance.',
            style: AppTypography.tiny.copyWith(color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}

class _EntitlementLine extends StatelessWidget {
  const _EntitlementLine(this.label, this.value, {this.emphasis = false});
  final String label;
  final String value;
  final bool emphasis;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.small)),
        Text(
          value,
          style: AppTypography.small.copyWith(
            fontWeight: emphasis ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SubscriptionStatus extends StatelessWidget {
  const _SubscriptionStatus({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.shieldGreen.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status.replaceAll('_', ' '),
      style: AppTypography.tiny.copyWith(
        color: AppColors.shieldGreen,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String _formatPaise(int value) => NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
).format(value / 100);

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
              membership.cardQrPayload?.isNotEmpty == true
                  ? 'View privilege card'
                  : 'Check card status',
              () => context.go('/portal/customer/privilege-card'),
            ),
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
      key: const Key('membership-loading-skeleton'),
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
