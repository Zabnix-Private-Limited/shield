import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/services/platform_file_actions.dart';
import '../../../../../shared/utils/shield_date_utils.dart';
import '../../../../../shared/widgets/shield_date_picker.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentSectionHeader(
              title: 'Reports',
              description:
                  'Reports now behave like report generation tools instead of settings rows, with shared filters, format selection, progress, and recent export visibility.',
            ),
            const SizedBox(height: 12),
            AgentPanelCard(
              title: 'Report Filters',
              subtitle:
                  'Use one filter bar for all shared agent reports instead of repeating the same controls on every card.',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DropdownButton<String>(
                    value: _format,
                    items: const [
                      DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                      DropdownMenuItem(value: 'EXCEL', child: Text('Excel')),
                      DropdownMenuItem(value: 'CSV', child: Text('CSV')),
                    ],
                    onChanged: (value) =>
                        setState(() => _format = value ?? 'PDF'),
                  ),
                  DropdownButton<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All statuses')),
                      DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                      DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                      DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                    ],
                    onChanged: (value) =>
                        setState(() => _status = value ?? 'ALL'),
                  ),
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search customer / keyword',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showShieldDateRangePicker(
                        context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: _dateRange,
                        title: 'Select Report Range',
                        startTitle: 'Select Start Date',
                        endTitle: 'Select End Date',
                        helperText:
                            'Choose the reporting window before exporting the selected SHIELD report.',
                      );
                      if (picked != null) {
                        setState(() {
                          _dateRange = picked;
                          _reportErrorMessage = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      _dateRange == null
                          ? 'Choose date range'
                          : ShieldDateUtils.formatDisplayDateRange(_dateRange!),
                    ),
                  ),
                  if (_dateRange != null ||
                      _searchController.text.trim().isNotEmpty ||
                      _status != 'ALL')
                    TextButton.icon(
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
                      label: const Text('Clear filters'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if ((_reportErrorMessage ?? '').trim().isNotEmpty) ...[
              AgentPanelCard(
                title: 'Report export needs attention',
                subtitle: _reportErrorMessage,
                action: TextButton.icon(
                  onPressed: _generating
                      ? null
                      : () {
                          setState(() => _reportErrorMessage = null);
                        },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Dismiss'),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AgentStatusBadge(
                      label: 'Retry available',
                      color: Colors.orange.shade700,
                      icon: Icons.refresh_rounded,
                    ),
                    if (_activeReportId != null)
                      FilledButton.tonalIcon(
                        onPressed: _generating
                            ? null
                            : () => _downloadReport(
                                  context,
                                  controller,
                                  _activeReportId!,
                                ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry export'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_generating) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                _activeReportId == null
                    ? 'Generating report export...'
                    : 'Generating ${_resolveReportTitle(reports, _activeReportId!)} export...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: reports.isEmpty
                  ? const AgentEmptyState(
                      icon: Icons.assessment_outlined,
                      title: 'No reports available',
                      message:
                          'Shared report templates have not been exposed to this workspace yet.',
                    )
                  : ListView(
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: reports
                              .map(
                                (report) => SizedBox(
                                  width: 320,
                                  child: AgentPanelCard(
                                    title:
                                        report['title']?.toString() ?? 'Report',
                                    subtitle: report['description']?.toString() ??
                                        'Shared export from the agent workspace.',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            AgentStatusBadge(
                                              label: _format,
                                              color: Colors.indigo.shade700,
                                            ),
                                            if (_dateRange != null)
                                              AgentStatusBadge(
                                                label: ShieldDateUtils
                                                    .formatDisplayDateRange(
                                                  _dateRange!,
                                                ),
                                                color: Colors.green.shade700,
                                              ),
                                            AgentStatusBadge(
                                              label: _status == 'ALL'
                                                  ? 'All statuses'
                                                  : _status,
                                              color: Colors.blueGrey.shade700,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: FilledButton.icon(
                                                onPressed: _generating
                                                    ? null
                                                    : () => _downloadReport(
                                                          context,
                                                          controller,
                                                          report['id']
                                                                  ?.toString() ??
                                                              '',
                                                        ),
                                                icon: const Icon(
                                                  Icons.download_rounded,
                                                ),
                                                label: Text(
                                                  _generating &&
                                                          _activeReportId ==
                                                              report['id']
                                                                  ?.toString()
                                                      ? 'Exporting...'
                                                      : 'Export',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        AgentPanelCard(
                          title: 'Recent Exports',
                          subtitle:
                              'A lightweight history of exports generated in this session.',
                          child: _recentExports.isEmpty
                              ? const AgentEmptyState(
                                  icon: Icons.download_done_outlined,
                                  title: 'No exports yet',
                                  message:
                                      'Generated reports will appear here after the first export in this session.',
                                )
                              : Column(
                                  children: _recentExports
                                      .map(
                                        (item) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(
                                            Icons.download_outlined,
                                          ),
                                          title: Text(item),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
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
      final result = await controller.runAgentReport(
        reportId,
        format: _format,
        dateFrom: _dateRange?.start.toIso8601String(),
        dateTo: _dateRange?.end.toIso8601String(),
        status: _status == 'ALL' ? null : _status,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      ) as Map<String, dynamic>;
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
      messenger.showSnackBar(
        SnackBar(content: Text(_reportErrorMessage!)),
      );
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
      return 'This SHIELD account can see the report, but export permission is missing for the selected action. Retry with the correct role or ask an administrator to grant export access.';
    }
    if (lowered.contains('401') || lowered.contains('unauthorized')) {
      return 'Your SHIELD session expired before the report export completed. Sign in again and retry the export.';
    }
    if (lowered.contains('network') || lowered.contains('socket')) {
      return 'The report export could not reach the server. Check the network connection and retry.';
    }
    if (lowered.contains('429')) {
      return 'Too many export attempts were sent in a short time. Wait a moment and retry the report.';
    }
    if (lowered.contains('empty')) {
      return 'The report completed without any exportable content for the selected filters. Adjust the filters and try again.';
    }
    return 'We could not export that report right now. Retry in a moment.';
  }
}
