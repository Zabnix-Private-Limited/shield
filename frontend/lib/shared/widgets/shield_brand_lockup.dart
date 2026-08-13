import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class ShieldBrandLockup extends StatelessWidget {
  const ShieldBrandLockup({
    super.key,
    this.compact = false,
    this.showWordmark = true,
    this.showTagline = false,
    this.alignment = CrossAxisAlignment.start,
  });

  final bool compact;
  final bool showWordmark;
  final bool showTagline;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 34.0 : 42.0;
    final wordmarkWidth = compact ? 118.0 : 154.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: markSize,
          height: markSize,
          padding: EdgeInsets.all(compact ? 5 : 6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            boxShadow: [
              BoxShadow(
                color: AppColors.shieldNavy.withValues(alpha: 0.06),
                blurRadius: compact ? 10 : 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset(
            'assets/logos/shield_mark.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.shield_outlined,
              color: AppColors.shieldBlue,
              size: markSize * 0.72,
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: alignment,
            children: [
              Image.asset(
                'assets/logos/shield_wordmark.png',
                width: wordmarkWidth,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Text(
                  'SHIELD',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.shieldNavy,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              if (showTagline) ...[
                const SizedBox(height: 4),
                Text(
                  'Sahakar Healthcare',
                  style: AppTypography.tiny.copyWith(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
