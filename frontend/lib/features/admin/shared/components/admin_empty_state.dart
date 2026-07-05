import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_button.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';
import 'admin_status_badge.dart';

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AdminColors.mutedSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AdminTypography.body.copyWith(
              color: AdminColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AdminTypography.small.copyWith(
              color: AdminColors.subtext,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          const AdminStatusBadge(label: 'Ready for action', color: AdminColors.secondary),
          const SizedBox(height: 8),
          if (onActionPressed == null)
            Text(
              actionLabel,
              style: AdminTypography.tiny.copyWith(color: AdminColors.caption),
            )
          else
            AppButton(
              text: actionLabel,
              onPressed: onActionPressed!,
              type: AppButtonType.secondary,
            ),
        ],
      ),
    );
  }
}
