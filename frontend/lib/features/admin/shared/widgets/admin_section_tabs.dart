import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminSectionTabs extends StatelessWidget {
  const AdminSectionTabs({
    super.key,
    required this.tabs,
    this.selectedTab,
    this.onSelected,
  });

  final List<String> tabs;
  final String? selectedTab;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final isSelected = selectedTab == null
              ? entry.key == 0
              : entry.value.trim().toLowerCase() ==
                    selectedTab!.trim().toLowerCase();
          return Padding(
            padding: EdgeInsets.only(
              right: entry.key == tabs.length - 1 ? 0 : 10,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onSelected == null ? null : () => onSelected!(entry.value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AdminColors.primary : AdminColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AdminColors.primary
                        : AdminColors.border,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: AdminTypography.small.copyWith(
                    color: isSelected
                        ? AdminColors.surface
                        : AdminColors.subtext,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
