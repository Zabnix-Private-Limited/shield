import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_card.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminSettingCard extends StatelessWidget {
  const AdminSettingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AdminColors.mutedSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AdminColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AdminTypography.body.copyWith(
                color: AdminColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AdminTypography.small.copyWith(
                color: AdminColors.subtext,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
