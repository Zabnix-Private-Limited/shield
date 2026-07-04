import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_card.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminChartCard extends StatelessWidget {
  const AdminChartCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AdminTypography.body.copyWith(
                fontWeight: FontWeight.w800,
                color: AdminColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AdminTypography.small.copyWith(color: AdminColors.caption),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(
                  Icons.show_chart_outlined,
                  color: AdminColors.primary,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
