import 'dart:convert';

import 'package:flutter/material.dart';

import '../../exports.dart';
import '../../../../../shared/services/platform_file_actions.dart';

class AdminBackendWorkspaceModule extends StatelessWidget {
  const AdminBackendWorkspaceModule({super.key, required this.snapshot});

  final AdminWorkspaceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final payload = snapshot.data;
    if (payload is! Map<String, dynamic>) {
      return const AdminEmptyState(
        title: 'Workspace payload unavailable',
        description:
            'The backend workspace loaded without a payload that the shared renderer can understand.',
        actionLabel: 'Verify the backend workspace contract.',
      );
    }

    final header = _HeaderData.fromMap(payload['header']);
    final toolbar = _ToolbarData.fromMap(payload['toolbar']);
    final metrics = _parseMetrics(payload['metrics']);
    final panels = Map<String, dynamic>.from(
      payload['panels'] as Map? ?? const <String, dynamic>{},
    );
    final controller = AdminWorkspaceControllerScope.maybeOf(context);
    final resolvedPrimaryAction = _resolveHeaderAction(
      label: header.primaryActionLabel,
      icon: Icons.bolt_outlined,
      toolbar: toolbar,
      controller: controller,
    );
    final resolvedSecondaryAction = _resolveHeaderAction(
      label: header.secondaryActionLabel,
      icon: Icons.tune_outlined,
      toolbar: toolbar,
      controller: controller,
    );

    return AdminPage(
      eyebrow: header.eyebrow,
      title: header.title,
      description: header.description,
      primaryAction: resolvedPrimaryAction,
      secondaryAction: resolvedSecondaryAction,
      metrics: metrics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (toolbar.isVisible) ...[
            AdminConsoleToolbar(
              searchHint: toolbar.searchHint,
              searchValue: controller?.query.search ?? '',
              tabs: toolbar.tabs,
              filters: toolbar.filters,
              selectedTab: controller?.query.tab,
              selectedFilter: controller?.query.status,
              onSearchChanged: controller?.updateSearch,
              onSearchCleared: controller == null
                  ? null
                  : () => controller.updateSearch(''),
              onTabSelected: controller?.selectTab,
              onFilterSelected: controller?.toggleStatus,
              onRefresh: controller?.refresh,
            ),
            const SizedBox(height: 18),
          ],
          AdminSplitWorkspace(
            left: _PanelView(
              panel: _PanelData.fromMap(panels['left']),
              onRefresh: controller?.refresh,
              controller: controller,
            ),
            center: _PanelView(
              panel: _PanelData.fromMap(panels['center']),
              onRefresh: controller?.refresh,
              controller: controller,
            ),
            right: panels['right'] == null
                ? null
                : _PanelView(
                    panel: _PanelData.fromMap(panels['right']),
                    onRefresh: controller?.refresh,
                    controller: controller,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PanelView extends StatelessWidget {
  const _PanelView({
    required this.panel,
    this.onRefresh,
    this.controller,
  });

  final _PanelData panel;
  final VoidCallback? onRefresh;
  final AdminWorkspaceController? controller;

  @override
  Widget build(BuildContext context) {
    return AdminStatCard(
      title: panel.title,
      subtitle: panel.subtitle,
      child: switch (panel.type) {
        _PanelType.table => _TablePanel(
          panel: panel,
          onRefresh: onRefresh,
          controller: controller,
        ),
        _PanelType.details =>
          _DetailsPanel(panel: panel, onRefresh: onRefresh),
        _PanelType.list => _ListPanel(
          panel: panel,
          onRefresh: onRefresh,
          controller: controller,
        ),
      },
    );
  }
}

class _TablePanel extends StatelessWidget {
  const _TablePanel({
    required this.panel,
    this.onRefresh,
    this.controller,
  });

  final _PanelData panel;
  final VoidCallback? onRefresh;
  final AdminWorkspaceController? controller;

  @override
  Widget build(BuildContext context) {
    if (panel.rows.isEmpty || panel.columns.isEmpty) {
      final emptyState = panel.emptyState;
      return AdminEmptyState(
        title: emptyState?.title ?? 'No rows available',
        description:
            emptyState?.description ??
            'This backend-driven table completed successfully but returned no rows.',
        actionLabel: emptyState?.actionLabel ?? 'Adjust the current filters.',
        onActionPressed: onRefresh,
      );
    }

    return AdminDataTable<Map<String, String>>(
      columns: panel.columns
          .map(
            (column) => AdminDataTableColumn<Map<String, String>>(
              key: column.key,
              label: column.label,
              sortKey: column.sortKey,
              valueBuilder: (row) => row[column.key] ?? 'N/A',
            ),
          )
          .toList(growable: false),
      rows: panel.rows,
      selectionKey: panel.selectionKey == null
          ? null
          : (row) => row[panel.selectionKey!] ?? '',
      selectedRowId: panel.selectedId,
      selectionEnabled: panel.selectionEnabled,
      sortedColumnKey: panel.sortKey,
      sortAscending: panel.sortDirection != 'desc',
      onSortChanged: controller == null
          ? null
          : (columnKey, ascending) => controller!.sortBy(
                columnKey,
                ascending: ascending,
              ),
      onRowTap: controller == null || panel.selectionKey == null
          ? null
          : (row) => controller!.selectRecord(row[panel.selectionKey!]),
      page: panel.pagination?.page,
      pageSize: panel.pagination?.pageSize,
      totalRows: panel.pagination?.totalRows,
      onPageChanged:
          controller == null ? null : (page) => controller!.goToPage(page),
      onPageSizeChanged: controller == null
          ? null
          : (pageSize) => controller!.changePageSize(pageSize),
      onExport: () => _exportTablePanel(context, panel),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.panel,
    this.onRefresh,
  });

  final _PanelData panel;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (panel.details.isEmpty) {
      final emptyState = panel.emptyState;
      return AdminEmptyState(
        title: emptyState?.title ?? 'No details available',
        description:
            emptyState?.description ??
            'This backend-driven detail panel completed successfully but returned no rows.',
        actionLabel: emptyState?.actionLabel ?? 'Check the workspace contract.',
        onActionPressed: onRefresh,
      );
    }

    return AdminDetailRows(
      rows: panel.details
          .map(
            (detail) => AdminDetailItem(
              label: detail['label'] ?? 'Detail',
              value: detail['value'] ?? 'N/A',
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({
    required this.panel,
    this.onRefresh,
    this.controller,
  });

  final _PanelData panel;
  final VoidCallback? onRefresh;
  final AdminWorkspaceController? controller;

  @override
  Widget build(BuildContext context) {
    if (panel.items.isEmpty) {
      final emptyState = panel.emptyState;
      return AdminEmptyState(
        title: emptyState?.title ?? 'No records available',
        description:
            emptyState?.description ??
            'This backend-driven list completed successfully but returned no records.',
        actionLabel: emptyState?.actionLabel ?? 'Check the current filters.',
        onActionPressed: onRefresh,
      );
    }

    return Column(
      children: panel.items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: controller == null || panel.selectionKey == null
                    ? null
                    : () => controller!.selectRecord(item[panel.selectionKey!]),
                child: AdminEntityCard(
                  item: AdminEntityItem(
                    title: item['title'] ?? 'Record',
                    subtitle: item['subtitle'] ?? '',
                    meta: item['meta'] ?? '',
                    status: item['status'] ?? 'UNKNOWN',
                    color: _statusColor(item['status']),
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _HeaderData {
  const _HeaderData({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.primaryActionLabel,
    this.secondaryActionLabel,
  });

  factory _HeaderData.fromMap(Object? raw) {
    final map = Map<String, dynamic>.from(
      raw as Map? ?? const <String, dynamic>{},
    );
    return _HeaderData(
      eyebrow: (map['eyebrow'] ?? 'Admin / Workspace').toString(),
      title: (map['title'] ?? 'Backend workspace').toString(),
      description: (map['description'] ?? '').toString(),
      primaryActionLabel: map['primaryActionLabel']?.toString(),
      secondaryActionLabel: map['secondaryActionLabel']?.toString(),
    );
  }

  final String eyebrow;
  final String title;
  final String description;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
}

class _ToolbarData {
  const _ToolbarData({
    required this.searchHint,
    required this.tabs,
    required this.filters,
  });

  factory _ToolbarData.fromMap(Object? raw) {
    final map = Map<String, dynamic>.from(
      raw as Map? ?? const <String, dynamic>{},
    );
    return _ToolbarData(
      searchHint: (map['searchHint'] ?? 'Search backend-driven workspace data')
          .toString(),
      tabs: List<String>.from(map['tabs'] as List? ?? const <String>[]),
      filters: List<String>.from(map['filters'] as List? ?? const <String>[]),
    );
  }

  final String searchHint;
  final List<String> tabs;
  final List<String> filters;

  bool get isVisible =>
      tabs.isNotEmpty || filters.isNotEmpty || searchHint.isNotEmpty;
}

class _PanelData {
  const _PanelData({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.items,
    required this.details,
    required this.columns,
    required this.rows,
    required this.emptyState,
    required this.selectionKey,
    required this.selectedId,
    required this.selectionEnabled,
    required this.sortKey,
    required this.sortDirection,
    required this.pagination,
  });

  factory _PanelData.fromMap(Object? raw) {
    final map = Map<String, dynamic>.from(
      raw as Map? ?? const <String, dynamic>{},
    );
    final typeValue = (map['type'] ?? 'details')
        .toString()
        .trim()
        .toLowerCase();
    return _PanelData(
      title: (map['title'] ?? 'Panel').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      type: switch (typeValue) {
        'table' => _PanelType.table,
        'list' => _PanelType.list,
        _ => _PanelType.details,
      },
      items: (map['items'] as List? ?? const <dynamic>[])
          .map((item) => Map<String, String>.from(item as Map))
          .toList(growable: false),
      details: (map['details'] as List? ?? const <dynamic>[])
          .map((item) => Map<String, String>.from(item as Map))
          .toList(growable: false),
      columns: (map['columns'] as List? ?? const <dynamic>[])
          .map((item) => _ColumnData.fromMap(item))
          .toList(growable: false),
      rows: (map['rows'] as List? ?? const <dynamic>[])
          .map((item) => Map<String, String>.from(item as Map))
          .toList(growable: false),
      emptyState: _EmptyStateData.fromMap(map['emptyState']),
      selectionKey: map['selectionKey']?.toString(),
      selectedId: map['selectedId']?.toString(),
      selectionEnabled: map['selectionEnabled'] == true,
      sortKey: map['sortKey']?.toString(),
      sortDirection: map['sortDirection']?.toString(),
      pagination: _PaginationData.fromMap(map['pagination']),
    );
  }

  final String title;
  final String subtitle;
  final _PanelType type;
  final List<Map<String, String>> items;
  final List<Map<String, String>> details;
  final List<_ColumnData> columns;
  final List<Map<String, String>> rows;
  final _EmptyStateData? emptyState;
  final String? selectionKey;
  final String? selectedId;
  final bool selectionEnabled;
  final String? sortKey;
  final String? sortDirection;
  final _PaginationData? pagination;
}

class _ColumnData {
  const _ColumnData({
    required this.key,
    required this.label,
    this.sortKey,
  });

  factory _ColumnData.fromMap(Object? raw) {
    final map = Map<String, dynamic>.from(
      raw as Map? ?? const <String, dynamic>{},
    );
    return _ColumnData(
      key: (map['key'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      sortKey: map['sortKey']?.toString(),
    );
  }

  final String key;
  final String label;
  final String? sortKey;
}

class _EmptyStateData {
  const _EmptyStateData({
    required this.title,
    required this.description,
    required this.actionLabel,
  });

  static _EmptyStateData? fromMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    return _EmptyStateData(
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      actionLabel: (map['actionLabel'] ?? '').toString(),
    );
  }

  final String title;
  final String description;
  final String actionLabel;
}

class _PaginationData {
  const _PaginationData({
    required this.page,
    required this.pageSize,
    required this.totalRows,
  });

  static _PaginationData? fromMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    return _PaginationData(
      page: _readPositiveInt(map['page'], 1),
      pageSize: _readPositiveInt(map['pageSize'], 25),
      totalRows: _readPositiveInt(map['totalRows'], 0),
    );
  }

  final int page;
  final int pageSize;
  final int totalRows;
}

enum _PanelType { list, details, table }

int _readPositiveInt(Object? value, int fallback) {
  final parsed = int.tryParse('${value ?? ''}');
  if (parsed == null || parsed <= 0) {
    return fallback;
  }
  return parsed;
}

Future<void> _exportTablePanel(BuildContext context, _PanelData panel) async {
  if (panel.columns.isEmpty || panel.rows.isEmpty) {
    return;
  }
  final header = panel.columns.map((column) => _escapeCsv(column.label)).join(',');
  final lines = <String>[
    header,
    ...panel.rows.map(
      (row) => panel.columns
          .map((column) => _escapeCsv(row[column.key] ?? ''))
          .join(','),
    ),
  ];
  final fileName = '${panel.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}.csv';
  final downloaded = await downloadPlatformFile(
    fileName: fileName,
    mimeType: 'text/csv',
    contentBase64: base64Encode(utf8.encode(lines.join('\n'))),
  );
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        downloaded
            ? 'Export ready: $fileName'
            : 'The export is ready, but automatic download is not available on this device.',
      ),
    ),
  );
}

String _escapeCsv(String value) {
  final normalized = value.replaceAll('"', '""');
  return '"$normalized"';
}

AdminActionItem? _resolveHeaderAction({
  required String? label,
  required IconData icon,
  required _ToolbarData toolbar,
  required AdminWorkspaceController? controller,
}) {
  if (label == null || controller == null) {
    return null;
  }
  final normalized = label.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  String? matchingTab() {
    for (final tab in toolbar.tabs) {
      final normalizedTab = tab.trim().toLowerCase();
      if (normalized.contains(normalizedTab)) {
        return tab;
      }
      if ((normalized.contains('auth') || normalized.contains('session')) &&
          normalizedTab.contains('auth')) {
        return tab;
      }
      if ((normalized.contains('device') || normalized.contains('delivery')) &&
          normalizedTab.contains('device')) {
        return tab;
      }
      if (normalized.contains('report') && normalizedTab.contains('report')) {
        return tab;
      }
      if (normalized.contains('commercial') &&
          normalizedTab.contains('commercial')) {
        return tab;
      }
      if (normalized.contains('activity') &&
          normalizedTab.contains('activity')) {
        return tab;
      }
    }
    return null;
  }

  String? matchingFilter() {
    for (final filter in toolbar.filters) {
      final normalizedFilter = filter.trim().toLowerCase();
      if (normalized.contains(normalizedFilter)) {
        return filter;
      }
      if (normalized.contains('approval') && normalizedFilter.contains('review')) {
        return filter;
      }
      if (normalized.contains('healthy') &&
          normalizedFilter.contains('healthy')) {
        return filter;
      }
    }
    return null;
  }

  final tab = matchingTab();
  if (tab != null) {
    return AdminActionItem(
      label: label,
      icon: icon,
      onPressed: () => controller.selectTab(tab),
    );
  }
  final filter = matchingFilter();
  if (filter != null) {
    return AdminActionItem(
      label: label,
      icon: icon,
      onPressed: () => controller.toggleStatus(filter),
    );
  }
  if (normalized.contains('refresh') || normalized.contains('reload')) {
    return AdminActionItem(
      label: label,
      icon: icon,
      onPressed: controller.refresh,
    );
  }
  return null;
}

List<AdminMetric> _parseMetrics(Object? raw) {
  return (raw as List? ?? const <dynamic>[])
      .map((item) => Map<String, dynamic>.from(item as Map))
      .map(
        (metric) => AdminMetric(
          label: (metric['label'] ?? '').toString(),
          value: (metric['value'] ?? '').toString(),
          note: (metric['note'] ?? '').toString(),
          color: _metricColor(metric),
          icon: _metricIcon(metric),
        ),
      )
      .toList(growable: false);
}

Color _metricColor(Map<String, dynamic> metric) {
  final normalized = '${metric['label'] ?? ''} ${metric['note'] ?? ''}'
      .toLowerCase();
  if (normalized.contains('unread') ||
      normalized.contains('unavailable') ||
      normalized.contains('pending')) {
    return AdminColors.warning;
  }
  if (normalized.contains('audit') || normalized.contains('alert')) {
    return AdminColors.secondary;
  }
  if (normalized.contains('active') ||
      normalized.contains('healthy') ||
      normalized.contains('approved') ||
      normalized.contains('configured')) {
    return AdminColors.success;
  }
  if (normalized.contains('wallet') || normalized.contains('reward')) {
    return AdminColors.rewards;
  }
  return AdminColors.primary;
}

IconData _metricIcon(Map<String, dynamic> metric) {
  final normalized = '${metric['label'] ?? ''} ${metric['note'] ?? ''}'
      .toLowerCase();
  if (normalized.contains('session')) {
    return Icons.devices_outlined;
  }
  if (normalized.contains('notification') || normalized.contains('alert')) {
    return Icons.notifications_active_outlined;
  }
  if (normalized.contains('audit')) {
    return Icons.fact_check_outlined;
  }
  if (normalized.contains('wallet')) {
    return Icons.account_balance_wallet_outlined;
  }
  if (normalized.contains('customer')) {
    return Icons.groups_2_outlined;
  }
  return Icons.data_thresholding_outlined;
}

Color _statusColor(String? status) {
  final normalized = (status ?? '').trim().toLowerCase();
  if (normalized.contains('unavailable') ||
      normalized.contains('failed') ||
      normalized.contains('overdue') ||
      normalized.contains('escalat')) {
    return AdminColors.danger;
  }
  if (normalized.contains('unread') ||
      normalized.contains('pending') ||
      normalized.contains('empty') ||
      normalized.contains('review')) {
    return AdminColors.warning;
  }
  if (normalized.contains('live') ||
      normalized.contains('healthy') ||
      normalized.contains('configured') ||
      normalized.contains('read') ||
      normalized.contains('active') ||
      normalized.contains('approved')) {
    return AdminColors.success;
  }
  return AdminColors.secondary;
}
