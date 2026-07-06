import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/membership.dart';
import '../../../shared/domain/customer_access_state.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'membership_card.dart';
import 'quick_actions.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.customer,
    required this.membership,
    required this.accessState,
    required this.wallet,
    required this.upcomingVisits,
    required this.documentCount,
    required this.quickActions,
  });

  final Customer customer;
  final Membership membership;
  final CustomerAccessState accessState;
  final DashboardWalletSummary wallet;
  final int upcomingVisits;
  final int documentCount;
  final List<DashboardQuickActionEntity> quickActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.shieldBlue, AppColors.shieldNavy],
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
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroStatBlock(
                    width: itemWidth,
                    label: accessState.serviceAccessEnabled
                        ? 'Wallet'
                        : 'Products',
                    value: accessState.serviceAccessEnabled
                        ? '₹${wallet.balance.toStringAsFixed(0)}'
                        : 'Browse only',
                    secondary: accessState.serviceAccessEnabled
                        ? '${wallet.pointsBalance.toStringAsFixed(0)} reward pts'
                        : 'Loaded products stay visible before card issue',
                  ),
                  _HeroStatBlock(
                    width: itemWidth,
                    label: accessState.serviceAccessEnabled
                        ? 'Activity'
                        : 'Card status',
                    value: accessState.serviceAccessEnabled
                        ? '$upcomingVisits visits'
                        : 'Pending',
                    secondary: accessState.serviceAccessEnabled
                        ? '$documentCount documents'
                        : 'Issued by admin or agent team',
                  ),
                ],
              );
            },
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

class _HeroStatBlock extends StatelessWidget {
  const _HeroStatBlock({
    required this.label,
    required this.value,
    required this.secondary,
    this.width,
  });

  final String label;
  final String value;
  final String secondary;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.tiny.copyWith(
              color: AppColors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.small.copyWith(
              color: AppColors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}
