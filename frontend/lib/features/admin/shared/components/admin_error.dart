import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminError extends StatelessWidget {
  const AdminError({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.danger.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: AdminTypography.small.copyWith(
          color: AdminColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
