import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AdminTypography.h3.copyWith(
            color: AdminColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AdminTypography.small.copyWith(
            color: AdminColors.caption,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
