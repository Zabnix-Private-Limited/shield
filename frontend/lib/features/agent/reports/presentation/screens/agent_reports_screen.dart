import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/services/platform_file_actions.dart';
import '../../../../../shared/utils/shield_date_utils.dart';
import '../../../../../shared/widgets/shield_date_picker.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_design_system.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentReportsScreen extends ConsumerStatefulWidget {
  const AgentReportsScreen({super.key});

  @override
  ConsumerState<AgentReportsScreen> createState() => _AgentReportsScreenState();
}

class _AgentReportsScreenState extends ConsumerState<AgentReportsScreen> {
  String _format = 'PDF';
  String _status = 'ALL';
  String? _selectedReportId;
  final _searchController = TextEditingController();
  DateTimeRange? _dateRange;
  bool _generating = false;
  String? _activeReportId;
  String? _reportErrorMessage;
  final List<String> _recentExports = <String>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(agentPortalControllerProvider);
    final reports = controller.availableReports;
    final selectedReportId =
        reports.any((report) => report['id']?.toString() == _selectedReportId)
        ? _selectedReportId
        : reports.isEmpty
        ? null
        : reports.first['id']?.toString();
    final selectedReport = reports.firstWhere(
      (report) => report['id']?.toString() == selectedReportId,
      orElse: () => <String, dynamic>{},
    );

    return AgentWorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AgentSectionHeader(
            title: 'Reports',
            description: 'Choose one report, set filters, and export it.',
          ),
          AgentUi.gapH(AgentSpacing.sectionGap),
          if ((_reportErrorMessage ?? '').trim().isNotEmpty) ...[
            AgentPanelCard(
              title: 'Export Needs Attention',
              subtitle: _reportErrorMessage,
              action: AgentGhostButton(
                onPressed: _generating
                    ? null
                    : () => setState(() => _reportErrorMessage = null),
                icon: const Icon(Icons.close_rounded),
                label: 'Dismiss',
              ),
              child: Wrap(
                spacing: AgentSpacing.xs,
                runSpacing: AgentSpacing.xs,
                children: [
                  AgentStatusBadge(
                    label: 'Retry available',
                    color: AgentColors.warning,
                    icon: Icons.refresh_rounded,
                  ),
                  if (_activeReportId != null)
                    AgentSecondaryButton(
                      onPressed: _generating
                          ? null
                          : () => _downloadReport(
                              context,
                              controller,
                              _activeReportId!,
                            ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: 'Retry Export',
                    ),
                ],
              ),
            ),
            AgentUi.gapH(AgentSpacing.sectionGap),
          ],
          if (reports.isEmpty)
            const AgentPanelCard(
              title: 'Generate New Report',
              subtitle: 'No report templates are available for this role.',
              child: AgentEmptyState(
                icon: Icons.insert_drive_file_outlined,
                title: 'No reports available',
                message: 'The shared report registry is empty right now.',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 1080;
                final chooser = AgentPanelCard(
                  title: 'Choose Report',
                  subtitle: 'Pick the export to generate.',
                  child: Column(
                    children: reports
                        .map(
                          (report) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => setState(
                                () => _selectedReportId = report['id']
                                    ?.toString(),
                              ),
                              borderRadius: AgentUi.radius(AgentRadius.panel),
                              child: AgentInsetSurface(
                                padding: AgentSpacing.compactInsets,
                                backgroundColor:
                                    selectedReportId == report['id']?.toString()
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : null,
                                borderColor:
                                    selectedReportId == report['id']?.toString()
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      color:
                                          selectedReportId ==
                                              report['id']?.toString()
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : AgentColors.accentIndigo,
                                    ),
                                    AgentUi.gapW(AgentSpacing.xs),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report['title']?.toString() ??
                                                'Report',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                          ),
                                          AgentUi.gapH(AgentSpacing.xxs),
                                          Text(
                                            report['description']?.toString() ??
                                                'Operational export.',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selectedReportId ==
                                        report['id']?.toString())
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
                final exportFlow = AgentPanelCard(
                  title: 'Generate New Report',
                  subtitle: 'Set filters, then export the selected report.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedReport.isNotEmpty) ...[
                        AgentInsetSurface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedReport['title']?.toString() ?? 'Report',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              AgentUi.gapH(AgentSpacing.xxs),
                              Text(
                                selectedReport['description']?.toString() ??
                                    'Operational export.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              AgentUi.gapH(AgentSpacing.xs),
                              Wrap(
                                spacing: AgentSpacing.xs,
                                runSpacing: AgentSpacing.xs,
                                children: [
                                  ...(selectedReport['formats'] as List?)
                                          ?.map(
                                            (format) => AgentStatusBadge(
                                              label: format.toString(),
                                              color: AgentColors.accentSlate,
                                            ),
                                          )
                                          .toList() ??
                                      const <Widget>[],
                                  AgentStatusBadge(
                                    label: _status == 'ALL'
                                        ? 'All statuses'
                                        : _status,
                                    color: AgentUi.statusColor(
                                      context,
                                      _status,
                                    ),
                                    icon: Icons.filter_alt_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        AgentUi.gapH(AgentSpacing.sm),
                      ],
                      AgentFilterWrap(
                        children: [
                          AgentFormFieldWidth(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _format,
                              decoration: const InputDecoration(
                                labelText: 'Format',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'PDF',
                                  child: Text('PDF'),
                                ),
                                DropdownMenuItem(
                                  value: 'EXCEL',
                                  child: Text('Excel'),
                                ),
                                DropdownMenuItem(
                                  value: 'CSV',
                                  child: Text('CSV'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _format = value ?? 'PDF'),
                            ),
                          ),
                          AgentFormFieldWidth(
                            width: 220,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'ALL',
                                  child: Text('All statuses'),
                                ),
                                DropdownMenuItem(
                                  value: 'PENDING',
                                  child: Text('Pending'),
                                ),
                                DropdownMenuItem(
                                  value: 'COMPLETED',
                                  child: Text('Completed'),
                                ),
                                DropdownMenuItem(
                                  value: 'CANCELLED',
                                  child: Text('Cancelled'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _status = value ?? 'ALL'),
                            ),
                          ),
                          AgentSearchField(
                            controller: _searchController,
                            labelText: 'Customer or Keyword',
                            width: 260,
                          ),
                          SizedBox(
                            width: 240,
                            child: AgentSecondaryButton(
                              onPressed: () async {
                                final picked = await showShieldDateRangePicker(
                                  context,
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  initialDateRange: _dateRange,
                                  title: 'Select Report Range',
                                  startTitle: 'Select Start Date',
                                  endTitle: 'Select End Date',
                                  helperText: 'Choose the reporting window.',
                                );
                                if (picked != null) {
                                  setState(() {
                                    _dateRange = picked;
                                    _reportErrorMessage = null;
                                  });
                                }
                              },
                              icon: const Icon(Icons.date_range_outlined),
                              label: _dateRange == null
                                  ? 'Choose Date Range'
                                  : ShieldDateUtils.formatDisplayDateRange(
                                      _dateRange!,
                                    ),
                            ),
                          ),
                          if (_dateRange != null ||
                              _searchController.text.trim().isNotEmpty ||
                              _status != 'ALL')
                            AgentGhostButton(
                              onPressed: _generating
                                  ? null
                                  : () {
                                      setState(() {
                                        _status = 'ALL';
                                        _dateRange = null;
                                        _reportErrorMessage = null;
                                        _searchController.clear();
                                      });
                                    },
                              icon: const Icon(Icons.refresh_rounded),
                              label: 'Clear Filters',
                            ),
                        ],
                      ),
                      AgentUi.gapH(AgentSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AgentPrimaryButton(
                          onPressed: _generating || selectedReportId == null
                              ? null
                              : () => _downloadReport(
                                  context,
                                  controller,
                                  selectedReportId,
                                ),
                          icon: const Icon(Icons.download_outlined),
                          label:
                              _generating && _activeReportId == selectedReportId
                              ? 'Exporting...'
                              : 'Export ${selectedReport['title']?.toString() ?? 'Report'}',
                          isLoading:
                              _generating &&
                              _activeReportId == selectedReportId,
                        ),
                      ),
                    ],
                  ),
                );
                if (stack) {
                  return Column(
                    children: [
                      chooser,
                      AgentUi.gapH(AgentSpacing.sectionGap),
                      exportFlow,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 360, child: chooser),
                    AgentUi.gapW(AgentSpacing.sectionGap),
                    Expanded(child: exportFlow),
                  ],
                );
              },
            ),
          AgentUi.gapH(AgentSpacing.sectionGap),
          AgentPanelCard(
            title: 'Recent Exports',
            subtitle: 'Exports generated in this session.',
            child: _recentExports.isEmpty
                ? const AgentEmptyState(
                    icon: Icons.download_done_outlined,
                    title: 'No exports yet',
                    message: 'Exports will appear here after the first run.',
                  )
                : Column(
                    children: _recentExports
                        .map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.download_outlined),
                            title: Text(item),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReport(
    BuildContext context,
    dynamic controller,
    String reportId,
  ) async {
    if (reportId.trim().isEmpty) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _generating = true;
      _activeReportId = reportId;
      _reportErrorMessage = null;
    });
    try {
      final result =
          await controller.runAgentReport(
                reportId,
                format: _format,
                dateFrom: _dateRange?.start.toIso8601String(),
                dateTo: _dateRange?.end.toIso8601String(),
                status: _status == 'ALL' ? null : _status,
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
              )
              as Map<String, dynamic>;
      final exportFile = result['exportFile'] is Map
          ? Map<String, dynamic>.from(result['exportFile'] as Map)
          : const <String, dynamic>{};
      if (exportFile.isEmpty) {
        throw StateError('The shared report export is empty.');
      }
      final downloaded = await downloadPlatformFile(
        fileName: exportFile['fileName']?.toString() ?? '$reportId.$_format',
        mimeType:
            exportFile['mimeType']?.toString() ?? 'application/octet-stream',
        contentBase64: exportFile['contentBase64']?.toString() ?? '',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _generating = false;
        _activeReportId = null;
        _recentExports.insert(
          0,
          '${_resolveReportTitle(controller.availableReports, reportId)} • ${exportFile['fileName']?.toString() ?? '$reportId.$_format'}',
        );
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            downloaded
                ? 'Report ready: ${exportFile['fileName'] ?? reportId}'
                : 'The report is ready, but automatic download is not available on this device.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _generating = false;
        _reportErrorMessage = _resolveExportError(error);
      });
      messenger.showSnackBar(SnackBar(content: Text(_reportErrorMessage!)));
    }
  }

  String _resolveReportTitle(
    List<Map<String, dynamic>> reports,
    String reportId,
  ) {
    final match = reports.cast<Map<String, dynamic>?>().firstWhere(
      (report) => report?['id']?.toString() == reportId,
      orElse: () => null,
    );
    return match?['title']?.toString() ?? 'report';
  }

  String _resolveExportError(Object error) {
    final message = error.toString().trim();
    final lowered = message.toLowerCase();
    if (lowered.contains('403') || lowered.contains('forbidden')) {
      return 'Export permission is missing for this report.';
    }
    if (lowered.contains('401') || lowered.contains('unauthorized')) {
      return 'Your SHIELD session expired before export completed.';
    }
    if (lowered.contains('network') || lowered.contains('socket')) {
      return 'The report export could not reach the server.';
    }
    if (lowered.contains('429')) {
      return 'Too many export attempts were sent in a short time.';
    }
    if (lowered.contains('empty')) {
      return 'This report has no exportable content for the selected filters.';
    }
    return 'We could not export that report right now.';
  }
}
