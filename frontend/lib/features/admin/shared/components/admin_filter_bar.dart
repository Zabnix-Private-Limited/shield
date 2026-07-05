import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminFilterBar extends StatelessWidget {
  const AdminFilterBar({
    super.key,
    required this.filters,
    this.selectedFilter,
    this.onSelected,
  });

  final List<String> filters;
  final String? selectedFilter;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (filter) {
                final isSelected =
                    filter.trim().toLowerCase() ==
                    selectedFilter?.trim().toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onSelected == null ? null : () => onSelected!(filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AdminColors.primary
                            : AdminColors.mutedSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AdminColors.primary
                              : AdminColors.border,
                        ),
                      ),
                      child: Text(
                        filter,
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
              },
            )
            .toList(),
      ),
    );
  }
}
