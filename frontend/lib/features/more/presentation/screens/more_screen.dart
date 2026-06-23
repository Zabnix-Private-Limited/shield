import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/portal_support.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: AppPageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explore more SHIELD features', style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                'Quick access to membership, rewards, documents, and app tools.',
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 20),
              _MoreTile(
                icon: Icons.card_membership,
                title: 'Membership Card',
                subtitle: 'Open your digital privilege card and member benefits.',
                onTap: () => context.go('/membership'),
              ),
              _MoreTile(
                icon: Icons.stars_rounded,
                title: 'Referral & Rewards',
                subtitle: 'View your referral code and understand how points are earned.',
                onTap: () => showPortalDetailsSheet(
                  context,
                  title: 'Referral & Rewards',
                  subtitle: 'Share referral code SHLD-NIHAL-2026 with new members. Points credit after approval only.',
                  meta: 'Frontend flow',
                  status: 'Ready',
                  highlights: const [
                    'Referral points are separate from cash wallet credits.',
                    'New member approval is the trigger for reward posting.',
                  ],
                ),
              ),
              _MoreTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Review alerts, reminders, and wallet updates.',
                onTap: () => context.go('/notifications'),
              ),
              _MoreTile(
                icon: Icons.description_outlined,
                title: 'Documents',
                subtitle: 'Open prescriptions, reports, and invoices.',
                onTap: () => context.go('/documents'),
              ),
              _MoreTile(
                icon: Icons.medical_services_outlined,
                title: 'Prescriptions',
                subtitle: 'Track refill-ready medicines and uploads.',
                onTap: () => context.go('/prescriptions'),
              ),
              _MoreTile(
                icon: Icons.receipt_long_outlined,
                title: 'Transactions',
                subtitle: 'Review cash and points activity.',
                onTap: () => context.go('/transactions'),
              ),
              _MoreTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Preferences, support, and app options.',
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.shieldBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.shieldBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.small.copyWith(color: AppColors.gray)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}
