import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    this.dark = false,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final background = dark
        ? AppColors.white.withValues(alpha: 0.14)
        : AppColors.lightGray;
    final textColor = dark ? AppColors.white : AppColors.darkGray;
    final captionColor = dark
        ? AppColors.white.withValues(alpha: 0.82)
        : AppColors.gray;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.small.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: AppTypography.tiny.copyWith(color: captionColor),
          ),
        ],
      ),
    );
  }
}
