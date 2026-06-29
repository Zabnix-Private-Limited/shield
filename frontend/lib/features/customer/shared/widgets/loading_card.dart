import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import 'glass_card.dart';

class LoadingCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const LoadingCard({
    super.key,
    this.title = 'Loading',
    this.subtitle = 'Fetching the latest SHIELD data for this section.',
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h4),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTypography.small),
          const SizedBox(height: 16),
          const AppSkeletonBlock(height: 16, width: 180),
          const SizedBox(height: 10),
          const AppSkeletonBlock(height: 16, width: 240),
          const SizedBox(height: 18),
          const AppSkeletonBlock(height: 88),
        ],
      ),
    );
  }
}
