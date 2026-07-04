import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminDataTableColumn<T> {
  const AdminDataTableColumn({
    required this.label,
    required this.valueBuilder,
  });

  final String label;
  final String Function(T value) valueBuilder;
}

class AdminDataTable<T> extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  final List<AdminDataTableColumn<T>> columns;
  final List<T> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              children: columns
                  .map(
                    (column) => Expanded(
                      child: Text(
                        column.label,
                        style: AdminTypography.tiny.copyWith(
                          color: AdminColors.caption,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ...rows.map(
            (row) => Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: columns
                    .map(
                      (column) => Expanded(
                        child: Text(
                          column.valueBuilder(row),
                          style: AdminTypography.small.copyWith(
                            color: AdminColors.subtext,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
