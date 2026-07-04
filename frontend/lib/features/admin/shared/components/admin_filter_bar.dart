import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({
    super.key,
    required this.filters,
  });

  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (filter) => Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AdminColors.mutedSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Text(
                  filter,
                  style: AdminTypography.small.copyWith(
                    color: AdminColors.subtext,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
