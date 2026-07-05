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

class AdminDataTable<T> extends StatefulWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  final List<AdminDataTableColumn<T>> columns;
  final List<T> rows;

  @override
  State<AdminDataTable<T>> createState() => _AdminDataTableState<T>();
}

class _AdminDataTableState<T> extends State<AdminDataTable<T>> {
  int? _sortedColumnIndex;
  bool _ascending = true;

  List<T> get _sortedRows {
    if (_sortedColumnIndex == null) {
      return widget.rows;
    }
    final rows = List<T>.from(widget.rows);
    final column = widget.columns[_sortedColumnIndex!];
    rows.sort((left, right) {
      final leftValue = column.valueBuilder(left).toLowerCase();
      final rightValue = column.valueBuilder(right).toLowerCase();
      return _ascending
          ? leftValue.compareTo(rightValue)
          : rightValue.compareTo(leftValue);
    });
    return rows;
  }

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
              children: widget.columns
                  .asMap()
                  .entries
                  .map(
                    (entry) => Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (_sortedColumnIndex == entry.key) {
                              _ascending = !_ascending;
                            } else {
                              _sortedColumnIndex = entry.key;
                              _ascending = true;
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                entry.value.label,
                                style: AdminTypography.tiny.copyWith(
                                  color: AdminColors.caption,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _sortedColumnIndex == entry.key
                                  ? (_ascending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward)
                                  : Icons.unfold_more,
                              size: 14,
                              color: AdminColors.caption,
                            ),
                          ],
                        ),
                      ),
                    )
                  )
                  .toList(),
            ),
          ),
          ..._sortedRows.map(
            (row) => Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: widget.columns
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
