import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/membership.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'membership_card.dart';
import 'quick_actions.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.customer,
    required this.membership,
    required this.wallet,
    required this.upcomingVisits,
    required this.documentCount,
    required this.quickActions,
  });

  final Customer customer;
  final Membership membership;
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
                      membership.tierLabel,
                      style: AppTypography.small.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              MembershipCard(status: customer.status),
            ],
          ),
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
                    label: 'Wallet',
                    value: '₹${wallet.balance.toStringAsFixed(0)}',
                    secondary:
                        '${wallet.pointsBalance.toStringAsFixed(0)} reward pts',
                  ),
                  _HeroStatBlock(
                    width: itemWidth,
                    label: 'Activity',
                    value: '$upcomingVisits visits',
                    secondary: '$documentCount documents',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          QuickActions(actions: quickActions),
        ],
      ),
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
