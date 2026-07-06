import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminPreviewSurface extends StatelessWidget {
  const AdminPreviewSurface({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF3F6FB),
        border: Border.all(color: AdminColors.border),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            size: 42,
            color: AdminColors.primary,
          ),
          const SizedBox(height: 12),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
