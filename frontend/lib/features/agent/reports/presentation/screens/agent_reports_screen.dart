import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/services/platform_file_actions.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentReportsScreen extends ConsumerStatefulWidget {
  const AgentReportsScreen({super.key});

  @override
  ConsumerState<AgentReportsScreen> createState() => _AgentReportsScreenState();
}

class _AgentReportsScreenState extends ConsumerState<AgentReportsScreen> {
  String _format = 'PDF';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agentPortalControllerProvider).ensureLoaded(),
    );
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reports',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Export acquisition, follow-up, appointment, document, referral, and performance reports from the shared reporting engine.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (reports.isEmpty)
              const Text('No report templates are available for this workspace yet.')
            else
              ...reports.map(
                (report) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(report['title']?.toString() ?? 'Report'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        report['description']?.toString() ??
                            'Shared export from the agent workspace.',
                      ),
                    ),
                    trailing: FilledButton(
                      onPressed: () => _downloadReport(
                        context,
                        controller,
                        report['id']?.toString() ?? '',
                      ),
                      child: Text('Export $_format'),
                    ),
                  ),
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
    try {
      final result = await controller.runAgentReport(
            reportId,
            format: _format,
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            downloaded
                ? 'Report ready: ${exportFile['fileName'] ?? reportId}'
                : 'The report is ready, but automatic download is not available on this device.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('We could not export that report right now.'),
        ),
      );
    }
  }
}
