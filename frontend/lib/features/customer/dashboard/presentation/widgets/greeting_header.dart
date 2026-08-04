import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/membership.dart';
import '../../../shared/domain/customer_access_state.dart';
import '../../../shared/theme/customer_design_tokens.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'membership_card.dart';
import 'quick_actions.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.customer,
    required this.membership,
    required this.accessState,
    required this.quickActions,
  });

  final Customer customer;
  final Membership membership;
  final CustomerAccessState accessState;
  final List<DashboardQuickActionEntity> quickActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1458D4), Color(0xFF073483)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName.toUpperCase(),
                      style: AppTypography.body.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accessState.serviceAccessEnabled
                          ? membership.tierLabel
                          : 'Membership pending approval',
                      style: AppTypography.small.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              MembershipCard(status: accessState.heroStatusLabel),
            ],
          ),
          if (!accessState.serviceAccessEnabled) ...[
            const SizedBox(height: 10),
            Text(
              'You can complete your profile and browse loaded products now. Care services unlock only after SHIELD issues your membership card.',
              style: AppTypography.small.copyWith(
                color: AppColors.white.withValues(alpha: 0.84),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(
                CustomerDesignTokens.controlRadius,
              ),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MembershipDetail(
                    label: 'Membership no.',
                    value: membership.customerCode.isEmpty
                        ? 'Pending issue'
                        : membership.customerCode,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: AppColors.white.withValues(alpha: 0.22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: () => context.go('/portal/customer/membership'),
                    borderRadius: BorderRadius.circular(10),
                    child: const _MembershipDetail(
                      label: 'Digital card',
                      value: 'Tap to view',
                      icon: Icons.qr_code_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MembershipDetail(
                  label: 'Privilege plan',
                  value: membership.tierLabel,
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MembershipDetail(
                  label: 'Valid until',
                  value:
                      '${membership.endDate.day.toString().padLeft(2, '0')} ${_monthLabel(membership.endDate.month)} ${membership.endDate.year}',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (accessState.serviceAccessEnabled)
            QuickActions(actions: quickActions)
          else
            const _PendingQuickActions(),
        ],
      ),
    );
  }
}

String _monthLabel(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

class _MembershipDetail extends StatelessWidget {
  const _MembershipDetail({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.tiny.copyWith(
            color: AppColors.white.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: AppColors.white),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.small.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PendingQuickActions extends StatelessWidget {
  const _PendingQuickActions();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleWidth = constraints.maxWidth;
        final twoColumnWidth = constraints.maxWidth >= 280
            ? (constraints.maxWidth - 12) / 2
            : singleWidth;

        Widget action(String label, String route, {bool full = false}) {
          return SizedBox(
            width: full ? singleWidth : twoColumnWidth,
            child: Material(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => context.go(route),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.small.copyWith(
                      color: AppColors.white,
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
            action('Complete profile', '/portal/customer/profile'),
            action('Browse products', '/portal/customer/services'),
            action(
              'Check membership',
              '/portal/customer/membership',
              full: true,
            ),
          ],
        );
      },
    );
  }
}
