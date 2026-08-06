import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';

class WalletFilters extends StatelessWidget {
  const WalletFilters({
    super.key,
    required this.selectedFilter,
    required this.onSelected,
  });

  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All cash',
            selected: selectedFilter == 'ALL',
            onTap: () => onSelected('ALL'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Credits',
            selected: selectedFilter == 'CREDITS',
            onTap: () => onSelected('CREDITS'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Debits',
            selected: selectedFilter == 'DEBITS',
            onTap: () => onSelected('DEBITS'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Reversals',
            selected: selectedFilter == 'REVERSALS',
            onTap: () => onSelected('REVERSALS'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.shieldBlue.withValues(alpha: 0.12)
              : AppColors.lightGray,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.shieldBlue : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.small.copyWith(
            color: selected ? AppColors.shieldBlue : AppColors.darkGray,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
