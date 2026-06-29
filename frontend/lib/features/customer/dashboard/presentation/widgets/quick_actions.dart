import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../dashboard/domain/entities/dashboard_entity.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.actions});

  final List<DashboardQuickActionEntity> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleWidth = constraints.maxWidth;
        final twoColumnWidth = constraints.maxWidth >= 280
            ? (constraints.maxWidth - 12) / 2
            : singleWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            for (var index = 0; index < actions.length; index++)
              _QuickActionButton(
                label: actions[index].label,
                width: actions.length.isOdd && index == actions.length - 1
                    ? singleWidth
                    : twoColumnWidth,
                onTap: () => context.go(actions[index].route),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.onTap,
    required this.width,
  });

  final String label;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
}
