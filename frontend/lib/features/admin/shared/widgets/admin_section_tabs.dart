import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminSectionTabs extends StatelessWidget {
  const AdminSectionTabs({
    super.key,
    required this.tabs,
  });

  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .asMap()
            .entries
            .map(
              (entry) => Container(
                margin: EdgeInsets.only(right: entry.key == tabs.length - 1 ? 0 : 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: entry.key == 0 ? AdminColors.primary : AdminColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: entry.key == 0 ? AdminColors.primary : AdminColors.border,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: AdminTypography.small.copyWith(
                    color: entry.key == 0 ? AdminColors.surface : AdminColors.subtext,
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
