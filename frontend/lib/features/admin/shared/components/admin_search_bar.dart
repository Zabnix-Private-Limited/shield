import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminSearchBar extends StatelessWidget {
  const AdminSearchBar({
    super.key,
    this.hintText = 'Search',
  });

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AdminColors.caption, size: 18),
          const SizedBox(width: 10),
          Text(
            hintText,
            style: AdminTypography.small.copyWith(color: AdminColors.caption),
          ),
        ],
      ),
    );
  }
}
