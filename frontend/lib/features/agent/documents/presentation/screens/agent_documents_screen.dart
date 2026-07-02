import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/services/platform_file_actions.dart';
import '../../../../../shared/utils/prescription_file_picker.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';

class AgentDocumentsScreen extends ConsumerStatefulWidget {
  const AgentDocumentsScreen({super.key});

  @override
  ConsumerState<AgentDocumentsScreen> createState() => _AgentDocumentsScreenState();
}

class _AgentDocumentsScreenState extends ConsumerState<AgentDocumentsScreen> {
  String _documentType = 'ID_PROOF';
  String _filter = 'ALL';
  String _query = '';

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
    final customerId = controller.selectedCustomerId;
    final docs = controller.customerDocuments.where((doc) {
      final status = (doc['status'] ?? '').toString().toUpperCase();
      final matchesFilter = _filter == 'ALL' || status == _filter;
      final combined =
          '${doc['fileName'] ?? ''} ${doc['documentType'] ?? ''} ${doc['status'] ?? ''}'
              .toLowerCase();
      final matchesQuery = combined.contains(_query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document workflow', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search documents',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filter,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All')),
                    DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                    DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                    DropdownMenuItem(value: 'VALIDATED', child: Text('Validated')),
                  ],
                  onChanged: (value) => setState(() => _filter = value ?? 'ALL'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_documentType),
                    initialValue: _documentType,
                    items: const [
                      DropdownMenuItem(value: 'ID_PROOF', child: Text('ID proof')),
                      DropdownMenuItem(value: 'PROFILE_PHOTO', child: Text('Profile photo')),
                      DropdownMenuItem(value: 'ADDRESS_PROOF', child: Text('Address proof')),
                      DropdownMenuItem(value: 'PRESCRIPTION', child: Text('Prescription')),
                    ],
                    onChanged: (value) => setState(() => _documentType = value ?? 'ID_PROOF'),
                    decoration: const InputDecoration(labelText: 'Document category'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: customerId == null
                      ? null
                      : () async {
                          final file = await pickPrescriptionFile();
                          if (file == null) {
                            return;
                          }
                          await ref
                              .read(agentPortalControllerProvider)
                              .uploadCustomerDocument(
                            customerId: customerId,
                            fileName: file.name,
                            documentType: _documentType,
                            fileBytes: file.bytes,
                            mimeType: file.mimeType ?? 'application/octet-stream',
                            fileSize: file.size,
                          );
                        },
                  child: const Text('Upload document'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              const Text('Select a customer to view and upload documents.')
            else
              ...docs.map(
                (doc) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${doc['fileName'] ?? 'Document'}'),
                  subtitle: Text(
                    '${_humanize(doc['documentType'])} • ${_humanize(doc['status'])} • ${_formatDate(doc['createdAt'])}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final url = await controller.getCustomerDocumentDownloadUrl(
                            doc['id']?.toString() ?? '',
                          );
                          if (!mounted || url.trim().isEmpty) {
                            return;
                          }
                          final opened = await openPlatformUrl(url);
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                opened
                                    ? 'Document opened in a new tab.'
                                    : 'The download link is ready, but opening it is not supported on this device.',
                              ),
                            ),
                          );
                        },
                        child: const Text('Preview'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final url = await ApiService.getDocumentDownloadUrl(
                            doc['id']?.toString() ?? '',
                          );
                          if (!mounted) {
                            return;
                          }
                          await Clipboard.setData(ClipboardData(text: url));
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Download link copied for this document.'),
                            ),
                          );
                        },
                        child: const Text('Copy link'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _humanize(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) {
    return 'Pending';
  }
  return text
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatDate(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) {
    return 'No upload date';
  }
  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return 'No upload date';
  }
  return '${parsed.toLocal().day.toString().padLeft(2, '0')}/${parsed.toLocal().month.toString().padLeft(2, '0')}/${parsed.toLocal().year}';
}
