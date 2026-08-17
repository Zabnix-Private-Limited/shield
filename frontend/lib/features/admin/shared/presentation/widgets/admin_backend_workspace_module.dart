import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../exports.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/services/api_service.dart';
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
        icon: Icons.person_add_alt_1_rounded,
        toolbar: toolbar,
        workspaceActions: workspaceActions,
        controller: controller,
        onWorkspaceAction: controller == null
            ? null
            : (action) => _handleAction(controller, action),
      ),
      secondaryAction: _resolveHeaderAction(
        label: header.secondaryActionLabel,
        icon: Icons.tune_outlined,
        toolbar: toolbar,
        workspaceActions: workspaceActions,
        controller: controller,
        onWorkspaceAction: controller == null
            ? null
            : (action) => _handleAction(controller, action),
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
      final formId = action.dialog?.formId ?? action.id;
      Map<String, dynamic>? form;
      try {
        form = await controller.loadForm(formId, recordId: recordId);
      } catch (_) {
        final payloadForms = (widget.snapshot.data is Map<String, dynamic>)
            ? (widget.snapshot.data as Map<String, dynamic>)['forms'] as List?
            : null;
        if (payloadForms != null) {
          final found = payloadForms.firstWhere(
            (f) =>
                f is Map &&
                (f['id'] == formId || f['id'] == action.id),
            orElse: () => null,
          );
          if (found is Map) {
            form = Map<String, dynamic>.from(found);
          }
        }
      }
      if (form == null) {
        _showMessage('Form configuration unavailable for this action.');
        return;
      }
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: panel.items.length,
      itemBuilder: (context, index) {
        final item = panel.items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: controller == null || panel.selectionKey == null
                ? null
                : () {
                    final code = item[panel.selectionKey!];
                    controller!.selectRecord(code);
                    if (code != null && code.toString().isNotEmpty) {
                      _showAgentPerformanceDialog(context, code.toString());
                    }
                  },
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
        );
      },
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
  required List<AdminWorkspaceActionDescriptor> workspaceActions,
  required AdminWorkspaceController? controller,
  required ValueChanged<AdminWorkspaceActionDescriptor>? onWorkspaceAction,
}) {
  if (label == null || controller == null) {
    return null;
  }
  final normalized = label.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  if (onWorkspaceAction != null && workspaceActions.isNotEmpty) {
    final matchingAction = workspaceActions.firstWhere(
      (a) =>
          a.label.trim().toLowerCase() == normalized ||
          a.id.trim().toLowerCase() == normalized.replaceAll(' ', '-') ||
          normalized.contains(a.label.trim().toLowerCase()),
      orElse: () => workspaceActions.first,
    );
    if (normalized.contains('create') ||
        normalized.contains('add') ||
        normalized.contains('new') ||
        matchingAction.label.trim().toLowerCase() == normalized) {
      return AdminActionItem(
        label: label,
        icon: icon,
        onPressed: () => onWorkspaceAction(matchingAction),
      );
    }
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
  if (onWorkspaceAction != null && workspaceActions.isNotEmpty) {
    return AdminActionItem(
      label: label,
      icon: icon,
      onPressed: () => onWorkspaceAction(workspaceActions.first),
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

  Widget _buildRequiredLabel(String text, {required bool isRequired}) {
    if (!isRequired) return Text(text);
    return Text.rich(
      TextSpan(
        text: text,
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(_WorkspaceFieldData field) {
    final selectedDept = (_selectedValues['department'] ?? '').trim().toLowerCase();
    final isAdminDept = selectedDept.contains('admin');

    if (isAdminDept && (field.key == 'branch' || field.key == 'accessScope')) {
      return const SizedBox.shrink();
    }

    final labelWidget = _buildRequiredLabel(field.label, isRequired: field.required);
    switch (field.type) {
      case 'dropdown':
      case 'select':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedValues[field.key]?.isEmpty ?? true
                ? null
                : _selectedValues[field.key],
            items: field.options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: field.readOnly
                ? null
                : (value) => setState(() {
                    _selectedValues[field.key] = value ?? '';
                  }),
            decoration: InputDecoration(
              label: labelWidget,
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
            title: labelWidget,
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
              label: labelWidget,
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
    final selectedDept = (_selectedValues['department'] ?? '').trim().toLowerCase();
    final isAdminDept = selectedDept.contains('admin');

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

    if (isAdminDept) {
      values['accessScope'] = 'ORGANIZATION';
      values['branch'] = '';
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

Future<void> _showAgentPerformanceDialog(
  BuildContext context,
  String code,
) async {
  showDialog(
    context: context,
    builder: (context) => _AgentPerformanceModal(code: code),
  );
}

class _AgentPerformanceModal extends StatefulWidget {
  const _AgentPerformanceModal({required this.code});

  final String code;

  @override
  State<_AgentPerformanceModal> createState() => _AgentPerformanceModalState();
}

class _AgentPerformanceModalState extends State<_AgentPerformanceModal> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getAgentProfilePerformance(widget.code);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 320,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.shieldBlue),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load agent profile details.', style: AppTypography.h4),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                );
              }

              final data = snapshot.data!;
              final agent = Map<String, dynamic>.from(data['agent'] ?? {});
              final metrics = Map<String, dynamic>.from(data['metrics'] ?? {});
              final breakdown = Map<String, dynamic>.from(data['earningsBreakdown'] ?? {});
              final formulaText = breakdown['formulaText']?.toString() ?? '';

              final customers = List<Map<String, dynamic>>.from(
                (data['addedCustomers'] as List? ?? []).map((x) => Map<String, dynamic>.from(x)),
              );
              final childReferrals = List<Map<String, dynamic>>.from(
                (data['childReferrals'] as List? ?? []).map((x) => Map<String, dynamic>.from(x)),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.shieldBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: AppColors.shieldBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  agent['name'] ?? 'Agent Profile',
                                  style: AppTypography.h3,
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.shieldGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    agent['status'] ?? 'ACTIVE',
                                    style: AppTypography.tiny.copyWith(
                                      color: AppColors.shieldGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${agent['code']} • ${agent['role']} • ${agent['branch']}',
                              style: AppTypography.small.copyWith(color: AppColors.gray),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatCard(
                        title: 'Direct Customers',
                        value: '${metrics['totalCustomersOnboarded'] ?? 0}',
                        icon: Icons.people_outline,
                        color: AppColors.shieldBlue,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        title: 'Active Memberships',
                        value: '${metrics['activeMembershipsAdded'] ?? 0}',
                        icon: Icons.card_membership_outlined,
                        color: AppColors.shieldGreen,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        title: 'Child Referrals',
                        value: '${metrics['totalChildReferrals'] ?? 0}',
                        icon: Icons.share_outlined,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        title: 'Calculated Earnings',
                        value: '${metrics['totalEarningsFormatted'] ?? '₹0'}',
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.amber.shade800,
                      ),
                    ],
                  ),
                  if (formulaText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calculate_outlined, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Earnings & Commission Formula Rate',
                                  style: AppTypography.tiny.copyWith(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formulaText,
                                  style: AppTypography.tiny.copyWith(
                                    color: AppColors.shieldNavy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TabBar(
                            labelColor: AppColors.shieldBlue,
                            unselectedLabelColor: AppColors.gray,
                            indicatorColor: AppColors.shieldBlue,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: [
                              Tab(text: 'Direct Customers (${customers.length})'),
                              Tab(text: 'Child Referrals Network (${childReferrals.length})'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: TabBarView(
                              children: [
                                customers.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No direct customers onboarded by this agent yet.',
                                          style: TextStyle(color: AppColors.gray),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: customers.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final cust = customers[index];
                                          return ListTile(
                                            dense: true,
                                            leading: CircleAvatar(
                                              backgroundColor: AppColors.lightGray,
                                              child: Text(
                                                (cust['name'] ?? 'C')[0].toUpperCase(),
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            title: Text(
                                              cust['name'] ?? 'Customer',
                                              style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
                                            ),
                                            subtitle: Text(
                                              '${cust['code']} • ${cust['mobile']} • Joined ${cust['joinedAt']}',
                                              style: AppTypography.small,
                                            ),
                                            trailing: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  cust['membershipTier'] ?? 'Standard',
                                                  style: AppTypography.small.copyWith(
                                                    color: AppColors.shieldBlue,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  'Wallet: ${cust['walletBalance'] ?? '₹0.00'}',
                                                  style: AppTypography.tiny.copyWith(
                                                    color: AppColors.darkGray,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                childReferrals.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No child referrals registered under this agent\'s customers yet.',
                                          style: TextStyle(color: AppColors.gray),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: childReferrals.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final child = childReferrals[index];
                                          return ListTile(
                                            dense: true,
                                            leading: CircleAvatar(
                                              backgroundColor: AppColors.shieldBlue.withValues(alpha: 0.1),
                                              child: const Icon(
                                                Icons.share_outlined,
                                                size: 18,
                                                color: AppColors.shieldBlue,
                                              ),
                                            ),
                                            title: Row(
                                              children: [
                                                Text(
                                                  child['name'] ?? 'Child Customer',
                                                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.shieldBlue.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Child Referral',
                                                    style: AppTypography.tiny.copyWith(
                                                      color: AppColors.shieldBlue,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Text(
                                              '${child['code']} • Referred by: ${child['parentCustomerName']} (${child['parentCustomerCode']}) • Joined ${child['joinedAt']}',
                                              style: AppTypography.small,
                                            ),
                                            trailing: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Earned: ${child['earnedCommission'] ?? '₹0'}',
                                                  style: AppTypography.small.copyWith(
                                                    color: AppColors.shieldGreen,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  'Wallet: ${child['walletBalance'] ?? '₹0.00'}',
                                                  style: AppTypography.tiny.copyWith(
                                                    color: AppColors.darkGray,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.h4.copyWith(color: AppColors.shieldNavy),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.tiny.copyWith(color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}
