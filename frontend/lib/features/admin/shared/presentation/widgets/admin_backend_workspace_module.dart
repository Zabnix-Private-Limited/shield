import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../exports.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/platform_file_actions.dart';

class AdminBackendWorkspaceModule extends StatefulWidget {
  const AdminBackendWorkspaceModule({super.key, required this.snapshot});

  final AdminWorkspaceSnapshot snapshot;

  @override
  State<AdminBackendWorkspaceModule> createState() =>
      _AdminBackendWorkspaceModuleState();
}

class _AdminBackendWorkspaceModuleState
    extends State<AdminBackendWorkspaceModule> {
  List<String> _selectedRowIds = const <String>[];
  bool _actionInFlight = false;

  @override
  Widget build(BuildContext context) {
    final payload = widget.snapshot.data;
    if (payload is! Map<String, dynamic>) {
      return const AdminEmptyState(
        title: 'Workspace payload unavailable',
        description:
            'This workspace loaded, but the renderer did not receive a usable payload.',
        actionLabel: 'Review the backend workspace response.',
      );
    }

    final header = _HeaderData.fromMap(payload['header']);
    final toolbar = _ToolbarData.fromMap(payload['toolbar']);
    final metrics = _parseMetrics(payload['metrics']);
    final actions = _parseWorkspaceActions(payload['actions']);
    final bulkActions = _parseWorkspaceActions(payload['bulkActions']);
    final panels = Map<String, dynamic>.from(
      payload['panels'] as Map? ?? const <String, dynamic>{},
    );
    final controller = AdminWorkspaceControllerScope.maybeOf(context);
    final workspaceActions = actions
        .where((action) => !action.requiresSelection && !action.allowBulk)
        .toList(growable: false);
    final recordActions = actions
        .where((action) => action.requiresSelection && !action.allowBulk)
        .toList(growable: false);
    final hasDetailPanel = panels['right'] != null;
    final topRow = _buildTopRow(
      leftPanel: _PanelData.fromMap(panels['left']),
      centerPanel: _PanelData.fromMap(panels['center']),
      controller: controller,
    );

    return AdminPage(
      eyebrow: header.eyebrow,
      title: header.title,
      description: header.description,
      primaryAction: _resolveHeaderAction(
        label: header.primaryActionLabel,
        icon: Icons.bolt_outlined,
        toolbar: toolbar,
        controller: controller,
      ),
      secondaryAction: _resolveHeaderAction(
        label: header.secondaryActionLabel,
        icon: Icons.tune_outlined,
        toolbar: toolbar,
        controller: controller,
      ),
      metrics: metrics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (toolbar.isVisible) ...[
            AdminConsoleToolbar(
              searchHint: toolbar.searchHint,
              searchValue: controller?.query.search ?? '',
              tabs: toolbar.tabs,
              showTabs: !hasDetailPanel,
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
              trailing: _WorkspaceActionMenus(
                workspaceActions: workspaceActions,
                recordActions: recordActions,
                bulkActions: bulkActions,
                actionInFlight: _actionInFlight,
                selectedRecordId: controller?.query.selectedId,
                selectedRowIds: _selectedRowIds,
                onWorkspaceAction: controller == null
                    ? null
                    : (action) => _handleAction(controller, action),
                onRecordAction: controller == null
                    ? null
                    : (action) => _handleAction(
                        controller,
                        action,
                        recordId: controller.query.selectedId,
                      ),
                onBulkAction: controller == null
                    ? null
                    : (action) => _handleBulkAction(controller, action),
              ),
            ),
            const SizedBox(height: 12),
          ],
          topRow,
          if (hasDetailPanel) ...[
            const SizedBox(height: 12),
            _DetailWorkspaceSection(
              tabs: toolbar.tabs,
              selectedTab: controller?.query.tab,
              onTabSelected: controller?.selectTab,
              panel: _PanelData.fromMap(panels['right']),
              onRefresh: controller?.refresh,
              controller: controller,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopRow({
    required _PanelData leftPanel,
    required _PanelData centerPanel,
    required AdminWorkspaceController? controller,
  }) {
    final hasLeftContent = leftPanel.hasVisibleContent;
    final center = _PanelView(
      panel: centerPanel,
      onRefresh: controller?.refresh,
      controller: controller,
      onSelectionChanged: _updateSelection,
      compact: true,
    );
    if (!hasLeftContent) {
      return center;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1180) {
          return Column(
            children: [
              _PanelView(
                panel: leftPanel,
                onRefresh: controller?.refresh,
                controller: controller,
                compact: true,
              ),
              const SizedBox(height: 12),
              center,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: _PanelView(
                panel: leftPanel,
                onRefresh: controller?.refresh,
                controller: controller,
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: center),
          ],
        );
      },
    );
  }

  Future<void> _handleAction(
    AdminWorkspaceController controller,
    AdminWorkspaceActionDescriptor action, {
    String? recordId,
  }) async {
    if (action.requiresSelection &&
        (recordId == null || recordId.trim().isEmpty)) {
      _showMessage('Select a record first.');
      return;
    }
    final confirmed = await _confirmIfNeeded(action);
    if (!confirmed) {
      return;
    }
    Map<String, Object?> payload = const <String, Object?>{};
    if (action.dialog?.type == 'FORM') {
      final form = await controller.loadForm(
        action.dialog?.formId ?? action.id,
        recordId: recordId,
      );
      final values = await _showWorkspaceFormDialog(form);
      if (values == null) {
        return;
      }
      payload = values;
    }
    setState(() => _actionInFlight = true);
    try {
      final result = await controller.executeWorkspaceAction(
        action,
        recordId: recordId,
        payload: payload,
      );
      await _handleActionResult(action, result);
    } finally {
      if (mounted) {
        setState(() => _actionInFlight = false);
      }
    }
  }

  Future<void> _handleBulkAction(
    AdminWorkspaceController controller,
    AdminWorkspaceActionDescriptor action,
  ) async {
    if (_selectedRowIds.isEmpty) {
      _showMessage('Select one or more rows first.');
      return;
    }
    final confirmed = await _confirmIfNeeded(action);
    if (!confirmed) {
      return;
    }
    setState(() => _actionInFlight = true);
    try {
      final result = await controller.executeBulkWorkspaceAction(
        action,
        recordIds: _selectedRowIds,
      );
      await _handleActionResult(action, result);
      if (mounted) {
        setState(() => _selectedRowIds = const <String>[]);
      }
    } finally {
      if (mounted) {
        setState(() => _actionInFlight = false);
      }
    }
  }

  Future<void> _handleActionResult(
    AdminWorkspaceActionDescriptor action,
    Map<String, dynamic> result,
  ) async {
    if ((result['contentBase64'] ?? '').toString().isNotEmpty) {
      await downloadPlatformFile(
        fileName: result['fileName']?.toString() ?? '${action.id}.bin',
        mimeType: result['mimeType']?.toString() ?? 'application/octet-stream',
        contentBase64: result['contentBase64']!.toString(),
      );
    }
    _showMessage(
      action.successMessage ??
          result['message']?.toString() ??
          '${action.label} completed successfully.',
    );
  }

  Future<bool> _confirmIfNeeded(AdminWorkspaceActionDescriptor action) async {
    final confirmation = action.confirmation;
    if (confirmation == null || !mounted) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(confirmation.title),
            content: Text(confirmation.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmation.confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<Map<String, Object?>?> _showWorkspaceFormDialog(
    Map<String, dynamic> form,
  ) {
    return showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => _WorkspaceFormDialog(form: form),
    );
  }

  void _updateSelection(List<String> ids) {
    if (listEquals(ids, _selectedRowIds)) {
      return;
    }
    setState(() {
      _selectedRowIds = ids;
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PanelView extends StatelessWidget {
  const _PanelView({
    required this.panel,
    this.onRefresh,
    this.controller,
    this.onSelectionChanged,
    this.compact = false,
  });

  final _PanelData panel;
  final VoidCallback? onRefresh;
  final AdminWorkspaceController? controller;
  final ValueChanged<List<String>>? onSelectionChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AdminStatCard(
      title: panel.title,
      subtitle: panel.subtitle,
      compact: compact,
      child: switch (panel.type) {
        _PanelType.table => _TablePanel(
          panel: panel,
          onRefresh: onRefresh,
          controller: controller,
          onSelectionChanged: onSelectionChanged,
        ),
        _PanelType.details => _DetailsPanel(panel: panel, onRefresh: onRefresh),
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
    this.onSelectionChanged,
  });

  final _PanelData panel;
  final VoidCallback? onRefresh;
  final AdminWorkspaceController? controller;
  final ValueChanged<List<String>>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    if (panel.rows.isEmpty || panel.columns.isEmpty) {
      final emptyState = panel.emptyState;
      return AdminEmptyState(
        title: emptyState?.title ?? 'No rows available',
        description:
            emptyState?.description ?? 'No records match the current view yet.',
        actionLabel:
            emptyState?.actionLabel ?? 'Adjust the filters or refresh.',
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
              valueBuilder: (row) => AppDisplayFormatters.formatCell(
                column.key,
                row[column.key] ?? '',
              ),
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
          : (columnKey, ascending) =>
                controller!.sortBy(columnKey, ascending: ascending),
      onRowTap: controller == null || panel.selectionKey == null
          ? null
          : (row) => controller!.selectRecord(row[panel.selectionKey!]),
      page: panel.pagination?.page,
      pageSize: panel.pagination?.pageSize,
      totalRows: panel.pagination?.totalRows,
      onPageChanged: controller == null
          ? null
          : (page) => controller!.goToPage(page),
      onPageSizeChanged: controller == null
          ? null
          : (pageSize) => controller!.changePageSize(pageSize),
      onSelectionChanged: onSelectionChanged,
      onExport: () => _exportTablePanel(context, panel),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.panel, this.onRefresh});

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
            'Select a record or adjust the current view to load details.',
        actionLabel: emptyState?.actionLabel ?? 'Refresh the details panel.',
        onActionPressed: onRefresh,
      );
    }

    return AdminDetailRows(
      rows: panel.details
          .map(
            (detail) => AdminDetailItem(
              label: detail['label'] ?? 'Detail',
              value: AppDisplayFormatters.formatCell(
                detail['label'] ?? 'detail',
                detail['value'] ?? '',
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.panel, this.onRefresh, this.controller});

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
            emptyState?.description ?? 'No records match the current view yet.',
        actionLabel:
            emptyState?.actionLabel ?? 'Adjust the filters or refresh.',
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
                    status: AppDisplayFormatters.formatStatusLabel(
                      item['status'] ?? 'UNKNOWN',
                    ),
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
      title: (map['title'] ?? 'Workspace').toString(),
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
      searchHint:
          (map['searchHint'] ?? 'Search records, names, IDs, or statuses')
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

  bool get hasVisibleContent =>
      items.isNotEmpty ||
      details.isNotEmpty ||
      rows.isNotEmpty ||
      columns.isNotEmpty ||
      emptyState != null;
}

class _ColumnData {
  const _ColumnData({required this.key, required this.label, this.sortKey});

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
  final header = panel.columns
      .map((column) => _escapeCsv(column.label))
      .join(',');
  final lines = <String>[
    header,
    ...panel.rows.map(
      (row) => panel.columns
          .map((column) => _escapeCsv(row[column.key] ?? ''))
          .join(','),
    ),
  ];
  final fileName =
      '${panel.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}.csv';
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

List<AdminWorkspaceActionDescriptor> _parseWorkspaceActions(Object? raw) {
  return (raw as List? ?? const <dynamic>[])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .map(AdminWorkspaceActionDescriptor.fromMap)
      .where((action) => action.id.trim().isNotEmpty)
      .toList(growable: false);
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
      if (normalized.contains('approval') &&
          normalizedFilter.contains('review')) {
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

IconData _iconForAction(String iconKey) {
  switch (iconKey.trim().toLowerCase()) {
    case 'edit':
      return Icons.edit_outlined;
    case 'pause_circle':
      return Icons.pause_circle_outline;
    case 'check_circle':
      return Icons.check_circle_outline;
    case 'delete':
      return Icons.delete_outline;
    case 'credit_card':
    case 'badge':
      return Icons.credit_card_outlined;
    case 'print':
      return Icons.print_outlined;
    case 'download':
      return Icons.download_outlined;
    case 'upload':
      return Icons.upload_file_outlined;
    case 'visibility':
      return Icons.visibility_outlined;
    default:
      return Icons.bolt_outlined;
  }
}

class _WorkspaceActionMenus extends StatelessWidget {
  const _WorkspaceActionMenus({
    required this.workspaceActions,
    required this.recordActions,
    required this.bulkActions,
    required this.actionInFlight,
    required this.selectedRecordId,
    required this.selectedRowIds,
    this.onWorkspaceAction,
    this.onRecordAction,
    this.onBulkAction,
  });

  final List<AdminWorkspaceActionDescriptor> workspaceActions;
  final List<AdminWorkspaceActionDescriptor> recordActions;
  final List<AdminWorkspaceActionDescriptor> bulkActions;
  final bool actionInFlight;
  final String? selectedRecordId;
  final List<String> selectedRowIds;
  final ValueChanged<AdminWorkspaceActionDescriptor>? onWorkspaceAction;
  final ValueChanged<AdminWorkspaceActionDescriptor>? onRecordAction;
  final ValueChanged<AdminWorkspaceActionDescriptor>? onBulkAction;

  @override
  Widget build(BuildContext context) {
    if (workspaceActions.isEmpty &&
        recordActions.isEmpty &&
        bulkActions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (workspaceActions.isNotEmpty)
          _ActionMenuButton(
            label: 'Workspace',
            actions: workspaceActions,
            enabled: !actionInFlight,
            onSelected: onWorkspaceAction,
          ),
        if (recordActions.isNotEmpty)
          _ActionMenuButton(
            label: 'Selected record',
            actions: recordActions,
            enabled:
                !actionInFlight &&
                (selectedRecordId?.trim().isNotEmpty ?? false),
            onSelected: onRecordAction,
          ),
        if (bulkActions.isNotEmpty)
          _ActionMenuButton(
            label: selectedRowIds.isEmpty
                ? 'Bulk actions'
                : 'Bulk actions (${selectedRowIds.length})',
            actions: bulkActions,
            enabled: !actionInFlight && selectedRowIds.isNotEmpty,
            onSelected: onBulkAction,
          ),
      ],
    );
  }
}

class _ActionMenuButton extends StatelessWidget {
  const _ActionMenuButton({
    required this.label,
    required this.actions,
    required this.enabled,
    this.onSelected,
  });

  final String label;
  final List<AdminWorkspaceActionDescriptor> actions;
  final bool enabled;
  final ValueChanged<AdminWorkspaceActionDescriptor>? onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AdminWorkspaceActionDescriptor>(
      enabled: enabled && onSelected != null,
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) => actions
          .map(
            (action) => PopupMenuItem<AdminWorkspaceActionDescriptor>(
              value: action,
              child: Row(
                children: [
                  Icon(_iconForAction(action.icon), size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(action.label)),
                ],
              ),
            ),
          )
          .toList(growable: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? AdminColors.surface : AdminColors.mutedSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AdminTypography.small.copyWith(
                color: enabled ? AdminColors.text : AdminColors.caption,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: enabled ? AdminColors.caption : AdminColors.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailWorkspaceSection extends StatelessWidget {
  const _DetailWorkspaceSection({
    required this.tabs,
    required this.selectedTab,
    required this.panel,
    this.onTabSelected,
    this.onRefresh,
    this.controller,
  });

  final List<String> tabs;
  final String? selectedTab;
  final ValueChanged<String>? onTabSelected;
  final _PanelData panel;
  final VoidCallback? onRefresh;
  final AdminWorkspaceController? controller;

  @override
  Widget build(BuildContext context) {
    return AdminStatCard(
      title: panel.title,
      subtitle: panel.subtitle,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tabs.isNotEmpty) ...[
            AdminSectionTabs(
              tabs: tabs,
              selectedTab: selectedTab,
              onSelected: onTabSelected,
            ),
            const SizedBox(height: 12),
          ],
          switch (panel.type) {
            _PanelType.table => _TablePanel(
              panel: panel,
              onRefresh: onRefresh,
              controller: controller,
            ),
            _PanelType.details => _DetailsPanel(
              panel: panel,
              onRefresh: onRefresh,
            ),
            _PanelType.list => _ListPanel(
              panel: panel,
              onRefresh: onRefresh,
              controller: controller,
            ),
          },
        ],
      ),
    );
  }
}

class _WorkspaceFormDialog extends StatefulWidget {
  const _WorkspaceFormDialog({required this.form});

  final Map<String, dynamic> form;

  @override
  State<_WorkspaceFormDialog> createState() => _WorkspaceFormDialogState();
}

class _WorkspaceFormDialogState extends State<_WorkspaceFormDialog> {
  late final List<_WorkspaceFieldData> _fields;
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Map<String, bool> _boolValues = <String, bool>{};
  final Map<String, String> _selectedValues = <String, String>{};

  @override
  void initState() {
    super.initState();
    _fields = (widget.form['fields'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (field) =>
              _WorkspaceFieldData.fromMap(Map<String, dynamic>.from(field)),
        )
        .toList(growable: false);
    for (final field in _fields) {
      switch (field.type) {
        case 'checkbox':
          _boolValues[field.key] = field.value.toLowerCase() == 'true';
          break;
        case 'select':
          _selectedValues[field.key] = field.value.isNotEmpty
              ? field.value
              : (field.options.isNotEmpty ? field.options.first : '');
          break;
        default:
          _controllers[field.key] = TextEditingController(text: field.value);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.form['title']?.toString() ?? 'Workspace form';
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _fields.map(_buildField).toList(growable: false),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_collectValues()),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildField(_WorkspaceFieldData field) {
    final label = field.required ? '${field.label} *' : field.label;
    switch (field.type) {
      case 'dropdown':
      case 'select':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedValues[field.key]?.isEmpty ?? true
                ? null
                : _selectedValues[field.key],
            items: field.options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  ),
                )
                .toList(growable: false),
            onChanged: field.readOnly
                ? null
                : (value) => setState(() {
                    _selectedValues[field.key] = value ?? '';
                  }),
            decoration: InputDecoration(
              labelText: label,
              filled: field.readOnly,
              fillColor: field.readOnly ? AppColors.lightGray : null,
            ),
          ),
        );
      case 'checkbox':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _boolValues[field.key] ?? false,
            onChanged: field.readOnly
                ? null
                : (value) => setState(() {
                    _boolValues[field.key] = value ?? false;
                  }),
            title: Text(label),
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextField(
            controller: _controllers[field.key],
            readOnly: field.readOnly,
            maxLines: field.type == 'textarea' ? 4 : 1,
            keyboardType: field.type == 'number'
                ? TextInputType.number
                : field.type == 'date'
                ? TextInputType.datetime
                : TextInputType.text,
            style: field.readOnly
                ? AppTypography.body.copyWith(color: AppColors.darkGray)
                : null,
            decoration: InputDecoration(
              labelText: label,
              helperText: field.helperText,
              filled: true,
              fillColor: field.readOnly ? AppColors.lightGray : AppColors.white,
            ),
          ),
        );
    }
  }

  Map<String, Object?> _collectValues() {
    final values = <String, Object?>{};
    for (final field in _fields) {
      switch (field.type) {
        case 'checkbox':
          values[field.key] = _boolValues[field.key] ?? false;
          break;
        case 'select':
          values[field.key] = _selectedValues[field.key] ?? '';
          break;
        default:
          values[field.key] = _controllers[field.key]?.text.trim() ?? '';
      }
    }
    return values;
  }
}

class _WorkspaceFieldData {
  const _WorkspaceFieldData({
    required this.key,
    required this.label,
    required this.type,
    required this.value,
    required this.required,
    required this.readOnly,
    required this.options,
    this.helperText,
  });

  factory _WorkspaceFieldData.fromMap(Map<String, dynamic> map) {
    return _WorkspaceFieldData(
      key: (map['key'] ?? map['name'] ?? '').toString(),
      label: (map['label'] ?? 'Field').toString(),
      type: (map['type'] ?? 'text').toString(),
      value: (map['value'] ?? '').toString(),
      required: map['required'] == true,
      readOnly: map['readonly'] == true || map['readOnly'] == true,
      options: (map['options'] as List? ?? const <dynamic>[])
          .map((option) => option.toString())
          .toList(growable: false),
      helperText: map['helperText']?.toString(),
    );
  }

  final String key;
  final String label;
  final String type;
  final String value;
  final bool required;
  final bool readOnly;
  final List<String> options;
  final String? helperText;
}
