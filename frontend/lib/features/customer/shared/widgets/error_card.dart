import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import 'glass_card.dart';
import 'primary_button.dart';

class ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorCard({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 34),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.h4),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            PrimaryButton(text: 'Retry', onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}
