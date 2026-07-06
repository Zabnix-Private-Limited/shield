import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminDataTableColumn<T> {
  const AdminDataTableColumn({
    required this.key,
    required this.label,
    required this.valueBuilder,
    this.sortKey,
  });

  final String key;
  final String label;
  final String Function(T value) valueBuilder;
  final String? sortKey;
}

class AdminDataTable<T> extends StatefulWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.selectionKey,
    this.selectedRowId,
    this.selectionEnabled = false,
    this.sortedColumnKey,
    this.sortAscending = true,
    this.onSortChanged,
    this.onRowTap,
    this.page,
    this.pageSize,
    this.totalRows,
    this.onPageChanged,
    this.onPageSizeChanged,
    this.onExport,
  });

  final List<AdminDataTableColumn<T>> columns;
  final List<T> rows;
  final String Function(T value)? selectionKey;
  final String? selectedRowId;
  final bool selectionEnabled;
  final String? sortedColumnKey;
  final bool sortAscending;
  final void Function(String columnKey, bool ascending)? onSortChanged;
  final void Function(T row)? onRowTap;
  final int? page;
  final int? pageSize;
  final int? totalRows;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final VoidCallback? onExport;

  @override
  State<AdminDataTable<T>> createState() => _AdminDataTableState<T>();
}

class _AdminDataTableState<T> extends State<AdminDataTable<T>> {
  int? _sortedColumnIndex;
  bool _ascending = true;
  final Set<String> _selectedRowIds = <String>{};

  bool get _usesServerSorting => widget.onSortChanged != null;
  bool get _usesPagination =>
      widget.page != null && widget.pageSize != null && widget.totalRows != null;

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(covariant AdminDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
  }

  List<T> get _sortedRows {
    if (_usesServerSorting || _sortedColumnIndex == null) {
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

  int get _selectedCount => _selectedRowIds.length;

  int get _page => widget.page ?? 1;

  int get _pageSize => widget.pageSize ?? math.max(widget.rows.length, 1);

  int get _totalRows => widget.totalRows ?? widget.rows.length;

  int get _totalPages => math.max(1, (_totalRows / _pageSize).ceil());

  bool get _allVisibleSelected {
    if (!widget.selectionEnabled || widget.selectionKey == null || widget.rows.isEmpty) {
      return false;
    }
    for (final row in widget.rows) {
      if (!_selectedRowIds.contains(widget.selectionKey!(row))) {
        return false;
      }
    }
    return true;
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
          if (widget.selectionEnabled || widget.onExport != null || _usesPagination)
            _TableUtilityBar(
              selectedCount: _selectedCount,
              showSelection: widget.selectionEnabled,
              showExport: widget.onExport != null,
              onExport: widget.onExport,
              page: _page,
              totalPages: _totalPages,
              showPagination: _usesPagination,
              pageSize: _pageSize,
              onPreviousPage: _page > 1 && widget.onPageChanged != null
                  ? () => widget.onPageChanged!(_page - 1)
                  : null,
              onNextPage: _page < _totalPages && widget.onPageChanged != null
                  ? () => widget.onPageChanged!(_page + 1)
                  : null,
              onPageSizeChanged: widget.onPageSizeChanged,
            ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              children: [
                if (widget.selectionEnabled)
                  SizedBox(
                    width: 44,
                    child: Checkbox(
                      value: _allVisibleSelected,
                      onChanged: (_) => _toggleSelectAllVisible(),
                    ),
                  ),
                ...widget.columns.asMap().entries.map(
                  (entry) => Expanded(
                    child: InkWell(
                      onTap: () => _handleSortTap(entry.key, entry.value),
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
                            _sortIcon(entry.key, entry.value),
                            size: 14,
                            color: AdminColors.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._sortedRows.map(
            (row) {
              final rowId = widget.selectionKey?.call(row);
              final isSelected =
                  rowId != null &&
                  (rowId == widget.selectedRowId || _selectedRowIds.contains(rowId));
              return InkWell(
                onTap: widget.onRowTap == null ? null : () => widget.onRowTap!(row),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AdminColors.primary.withValues(alpha: 0.06)
                        : null,
                    border: const Border(
                      bottom: BorderSide(color: AdminColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (widget.selectionEnabled)
                        SizedBox(
                          width: 44,
                          child: Checkbox(
                            value: rowId != null && _selectedRowIds.contains(rowId),
                            onChanged: rowId == null
                                ? null
                                : (_) => _toggleRowSelection(rowId),
                          ),
                        ),
                      ...widget.columns.map(
                        (column) => Expanded(
                          child: Text(
                            column.valueBuilder(row),
                            style: AdminTypography.small.copyWith(
                              color: AdminColors.subtext,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _syncSelection() {
    _selectedRowIds
      ..clear()
      ..addAll(
        widget.selectedRowId == null ? const <String>[] : <String>[widget.selectedRowId!],
      );
  }

  void _handleSortTap(int index, AdminDataTableColumn<T> column) {
    final resolvedSortKey = column.sortKey ?? column.key;
    if (_usesServerSorting) {
      final isCurrentColumn = widget.sortedColumnKey == resolvedSortKey;
      final nextAscending = isCurrentColumn ? !widget.sortAscending : true;
      widget.onSortChanged!(resolvedSortKey, nextAscending);
      return;
    }

    setState(() {
      if (_sortedColumnIndex == index) {
        _ascending = !_ascending;
      } else {
        _sortedColumnIndex = index;
        _ascending = true;
      }
    });
  }

  IconData _sortIcon(int index, AdminDataTableColumn<T> column) {
    if (_usesServerSorting) {
      final resolvedSortKey = column.sortKey ?? column.key;
      if (widget.sortedColumnKey != resolvedSortKey) {
        return Icons.unfold_more;
      }
      return widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward;
    }
    if (_sortedColumnIndex == index) {
      return _ascending ? Icons.arrow_upward : Icons.arrow_downward;
    }
    return Icons.unfold_more;
  }

  void _toggleSelectAllVisible() {
    final keyBuilder = widget.selectionKey;
    if (!widget.selectionEnabled || keyBuilder == null) {
      return;
    }
    setState(() {
      if (_allVisibleSelected) {
        for (final row in widget.rows) {
          _selectedRowIds.remove(keyBuilder(row));
        }
      } else {
        for (final row in widget.rows) {
          _selectedRowIds.add(keyBuilder(row));
        }
      }
    });
  }

  void _toggleRowSelection(String rowId) {
    setState(() {
      if (_selectedRowIds.contains(rowId)) {
        _selectedRowIds.remove(rowId);
      } else {
        _selectedRowIds.add(rowId);
      }
    });
  }
}

class _TableUtilityBar extends StatelessWidget {
  const _TableUtilityBar({
    required this.selectedCount,
    required this.showSelection,
    required this.showExport,
    required this.onExport,
    required this.page,
    required this.totalPages,
    required this.showPagination,
    required this.pageSize,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onPageSizeChanged,
  });

  final int selectedCount;
  final bool showSelection;
  final bool showExport;
  final VoidCallback? onExport;
  final int page;
  final int totalPages;
  final bool showPagination;
  final int pageSize;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<int>? onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (showSelection)
            Text(
              '$selectedCount selected',
              style: AdminTypography.tiny.copyWith(
                color: AdminColors.caption,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (showExport)
            TextButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Export'),
            ),
          if (showPagination)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Page $page of $totalPages',
                  style: AdminTypography.tiny.copyWith(
                    color: AdminColors.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: onPreviousPage,
                  child: const Text('Previous'),
                ),
                TextButton(
                  onPressed: onNextPage,
                  child: const Text('Next'),
                ),
                if (onPageSizeChanged != null)
                  PopupMenuButton<int>(
                    tooltip: 'Rows per page',
                    onSelected: onPageSizeChanged,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 25, child: Text('25 / page')),
                      PopupMenuItem(value: 50, child: Text('50 / page')),
                      PopupMenuItem(value: 100, child: Text('100 / page')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AdminColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Text(
                        '$pageSize / page',
                        style: AdminTypography.tiny.copyWith(
                          color: AdminColors.subtext,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Text(
                  'Rows per page',
                  style: AdminTypography.tiny.copyWith(
                    color: AdminColors.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
