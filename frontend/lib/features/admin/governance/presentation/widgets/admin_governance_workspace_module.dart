import 'package:flutter/material.dart';

import '../../../shared/exports.dart';

class AdminGovernanceWorkspaceModule extends StatelessWidget {
  const AdminGovernanceWorkspaceModule({super.key, required this.snapshot});

  final AdminWorkspaceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final payload = snapshot.data;
    if (payload is! Map<String, dynamic>) {
      return const AdminEmptyState(
        title: 'Workspace payload unavailable',
        description:
            'The governance workspace loaded without a backend payload that the shared renderer can understand.',
        actionLabel: 'Verify the backend workspace contract.',
      );
    }

    final header = _HeaderData.fromMap(payload['header']);
    final toolbar = _ToolbarData.fromMap(payload['toolbar']);
    final metrics = _parseMetrics(payload['metrics']);
    final panels = Map<String, dynamic>.from(
      payload['panels'] as Map? ?? const <String, dynamic>{},
    );

    return AdminPage(
      eyebrow: header.eyebrow,
      title: header.title,
      description: header.description,
      primaryAction: header.primaryActionLabel == null
          ? null
          : AdminActionItem(
              label: header.primaryActionLabel!,
              icon: Icons.bolt_outlined,
            ),
      secondaryAction: header.secondaryActionLabel == null
          ? null
          : AdminActionItem(
              label: header.secondaryActionLabel!,
              icon: Icons.tune_outlined,
            ),
      metrics: metrics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (toolbar.isVisible) ...[
            AdminConsoleToolbar(
              searchHint: toolbar.searchHint,
              tabs: toolbar.tabs,
              filters: toolbar.filters,
            ),
            const SizedBox(height: 18),
          ],
          AdminSplitWorkspace(
            left: _PanelView(panel: _PanelData.fromMap(panels['left'])),
            center: _PanelView(panel: _PanelData.fromMap(panels['center'])),
            right: panels['right'] == null
                ? null
                : _PanelView(panel: _PanelData.fromMap(panels['right'])),
          ),
        ],
      ),
    );
  }
}

class _PanelView extends StatelessWidget {
  const _PanelView({required this.panel});

  final _PanelData panel;

  @override
  Widget build(BuildContext context) {
    return AdminStatCard(
      title: panel.title,
      subtitle: panel.subtitle,
      child: switch (panel.type) {
        _PanelType.table => _TablePanel(panel: panel),
        _PanelType.details => _DetailsPanel(panel: panel),
        _PanelType.list => _ListPanel(panel: panel),
      },
    );
  }
}

class _TablePanel extends StatelessWidget {
  const _TablePanel({required this.panel});

  final _PanelData panel;

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
      );
    }

    return AdminDataTable<Map<String, String>>(
      columns: panel.columns
          .map(
            (column) => AdminDataTableColumn<Map<String, String>>(
              label: column.label,
              valueBuilder: (row) => row[column.key] ?? 'N/A',
            ),
          )
          .toList(growable: false),
      rows: panel.rows,
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.panel});

  final _PanelData panel;

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
  const _ListPanel({required this.panel});

  final _PanelData panel;

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
      );
    }

    return Column(
      children: panel.items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
      eyebrow: (map['eyebrow'] ?? 'Admin / Governance').toString(),
      title: (map['title'] ?? 'Governance workspace').toString(),
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
}

class _ColumnData {
  const _ColumnData({required this.key, required this.label});

  factory _ColumnData.fromMap(Object? raw) {
    final map = Map<String, dynamic>.from(
      raw as Map? ?? const <String, dynamic>{},
    );
    return _ColumnData(
      key: (map['key'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
    );
  }

  final String key;
  final String label;
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

enum _PanelType { list, details, table }

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
  if (normalized.contains('unread') || normalized.contains('unavailable')) {
    return AdminColors.warning;
  }
  if (normalized.contains('audit')) {
    return AdminColors.secondary;
  }
  if (normalized.contains('active') || normalized.contains('healthy')) {
    return AdminColors.success;
  }
  return AdminColors.primary;
}

IconData _metricIcon(Map<String, dynamic> metric) {
  final normalized = '${metric['label'] ?? ''} ${metric['note'] ?? ''}'
      .toLowerCase();
  if (normalized.contains('session')) {
    return Icons.devices_outlined;
  }
  if (normalized.contains('notification')) {
    return Icons.notifications_active_outlined;
  }
  if (normalized.contains('audit')) {
    return Icons.fact_check_outlined;
  }
  if (normalized.contains('setting')) {
    return Icons.tune_outlined;
  }
  return Icons.data_thresholding_outlined;
}

Color _statusColor(String? status) {
  final normalized = (status ?? '').trim().toLowerCase();
  if (normalized.contains('unavailable') || normalized.contains('failed')) {
    return AdminColors.danger;
  }
  if (normalized.contains('unread') ||
      normalized.contains('pending') ||
      normalized.contains('empty')) {
    return AdminColors.warning;
  }
  if (normalized.contains('live') ||
      normalized.contains('healthy') ||
      normalized.contains('configured') ||
      normalized.contains('read')) {
    return AdminColors.success;
  }
  return AdminColors.secondary;
}
