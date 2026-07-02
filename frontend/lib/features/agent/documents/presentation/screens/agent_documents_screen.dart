import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/services/platform_file_actions.dart';
import '../../../../../shared/utils/prescription_file_picker.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_experience_widgets.dart';
import '../../../shared/presentation/widgets/agent_section_header.dart';

class AgentDocumentsScreen extends ConsumerStatefulWidget {
  const AgentDocumentsScreen({super.key});

  @override
  ConsumerState<AgentDocumentsScreen> createState() =>
      _AgentDocumentsScreenState();
}

class _AgentDocumentsScreenState extends ConsumerState<AgentDocumentsScreen> {
  String _documentType = 'ID_PROOF';
  String _filter = 'ALL';
  String _query = '';
  String _sort = 'NEWEST';

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
    final selectedCustomer = controller.selectedCustomer;
    final customerName =
        selectedCustomer['firstName']?.toString().isNotEmpty == true
            ? '${selectedCustomer['firstName']} ${selectedCustomer['lastName'] ?? ''}'
                .trim()
            : 'Select a customer from Customers';

    final docs = controller.customerDocuments.where((doc) {
      final status = (doc['status'] ?? '').toString().toUpperCase();
      final matchesFilter = _filter == 'ALL' || status == _filter;
      final combined =
          '${doc['fileName'] ?? ''} ${doc['documentType'] ?? ''} ${doc['status'] ?? ''}'
              .toLowerCase();
      final matchesQuery = combined.contains(_query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse((a['createdAt'] ?? '').toString());
        final bDate = DateTime.tryParse((b['createdAt'] ?? '').toString());
        if (_sort == 'OLDEST') {
          return (aDate ?? DateTime(1900)).compareTo(bDate ?? DateTime(1900));
        }
        return (bDate ?? DateTime(1900)).compareTo(aDate ?? DateTime(1900));
      });

    final uploadedTypes = docs
        .map((doc) => (doc['documentType'] ?? '').toString().toUpperCase())
        .toSet();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgentSectionHeader(
              title: 'Documents',
              description:
                  'This customer-first document flow now behaves more like a lightweight DMS: required files, status badges, verification states, sorting, and quick preview actions.',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 980;
                final left = _buildRequiredDocumentsCard(
                  context,
                  customerId,
                  customerName,
                  uploadedTypes,
                  controller,
                );
                final right = _buildHistoryCard(context, controller, docs);
                if (stack) {
                  return Column(
                    children: [left, const SizedBox(height: 16), right],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: left),
                    const SizedBox(width: 16),
                    Expanded(child: right),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredDocumentsCard(
    BuildContext context,
    String? customerId,
    String customerName,
    Set<String> uploadedTypes,
    dynamic controller,
  ) {
    const requiredDocuments = [
      _RequiredDoc(type: 'ID_PROOF', label: 'Aadhaar / Government ID'),
      _RequiredDoc(type: 'ADDRESS_PROOF', label: 'Address Proof'),
      _RequiredDoc(type: 'PROFILE_PHOTO', label: 'Profile Photo'),
      _RequiredDoc(type: 'PRESCRIPTION', label: 'Prescription'),
    ];

    return AgentPanelCard(
      title: 'Required Documents',
      subtitle:
          'Choose a document type, then upload or replace it while staying anchored to the selected customer.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(customerName),
            subtitle: Text(
              customerId == null
                  ? 'Choose a customer before uploading documents.'
                  : 'Customer selected for document management.',
            ),
          ),
          const SizedBox(height: 12),
          ...requiredDocuments.map(
            (doc) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: Row(
                children: [
                  AgentStatusBadge(
                    label: uploadedTypes.contains(doc.type)
                        ? 'Uploaded'
                        : 'Missing',
                    color: uploadedTypes.contains(doc.type)
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    icon: uploadedTypes.contains(doc.type)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(doc.label)),
                  TextButton(
                    onPressed: () => setState(() => _documentType = doc.type),
                    child: Text(_documentType == doc.type ? 'Selected' : 'Choose'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: customerId == null
                    ? null
                    : () => _uploadDocument(
                          controller,
                          customerId: customerId,
                          documentType: _documentType,
                          replaceExisting: false,
                        ),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload'),
              ),
              OutlinedButton.icon(
                onPressed: customerId == null
                    ? null
                    : () => _uploadDocument(
                          controller,
                          customerId: customerId,
                          documentType: _documentType,
                          replaceExisting: true,
                        ),
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Replace'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Supported formats: PDF, JPG, PNG, WEBP. Verification and rejection notes appear in history when available from the backend.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    dynamic controller,
    List<Map<String, dynamic>> docs,
  ) {
    return AgentPanelCard(
      title: 'Document History',
      subtitle:
          'Search, filter, sort, preview, and inspect the verification state of customer files.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search documents',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              DropdownButton<String>(
                value: _filter,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All statuses')),
                  DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                  DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                  DropdownMenuItem(value: 'VALIDATED', child: Text('Validated')),
                  DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                ],
                onChanged: (value) => setState(() => _filter = value ?? 'ALL'),
              ),
              DropdownButton<String>(
                value: _sort,
                items: const [
                  DropdownMenuItem(value: 'NEWEST', child: Text('Newest first')),
                  DropdownMenuItem(value: 'OLDEST', child: Text('Oldest first')),
                ],
                onChanged: (value) => setState(() => _sort = value ?? 'NEWEST'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (docs.isEmpty)
            const AgentEmptyState(
              icon: Icons.folder_copy_outlined,
              title: 'No documents found',
              message:
                  'Select a customer and upload the first required file to start the document timeline.',
            )
          else
            ...docs.map(
              (doc) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(_docIcon(doc['fileName']?.toString())),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc['fileName']?.toString() ?? 'Document',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AgentStatusBadge(
                                label: _humanize(doc['status']),
                                color: _statusColor(doc['status']?.toString()),
                              ),
                              AgentStatusBadge(
                                label: _humanize(doc['documentType']),
                                color: Colors.indigo.shade700,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Uploaded ${_formatDate(doc['createdAt'])}'
                            '${(doc['verifiedAt'] ?? '').toString().trim().isNotEmpty ? ' • Verified ${_formatDate(doc['verifiedAt'])}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if ((doc['verificationNotes'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Verification note: ${doc['verificationNotes']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if ((doc['rejectionReason'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Rejected reason: ${doc['rejectionReason']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Preview',
                          onPressed: () => _previewDocument(
                            context,
                            controller,
                            doc['id']?.toString() ?? '',
                          ),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        IconButton(
                          tooltip: 'Copy link',
                          onPressed: () => _copyLink(
                            context,
                            doc['id']?.toString() ?? '',
                          ),
                          icon: const Icon(Icons.link_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument(
    dynamic controller, {
    required String customerId,
    required String documentType,
    required bool replaceExisting,
  }) async {
    final file = await pickPrescriptionFile();
    if (file == null) {
      return;
    }
    await controller.uploadCustomerDocument(
      customerId: customerId,
      fileName: file.name,
      documentType: documentType,
      fileBytes: file.bytes,
      mimeType: file.mimeType ?? 'application/octet-stream',
      fileSize: file.size,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          replaceExisting
              ? 'Document replacement uploaded successfully.'
              : 'Document uploaded successfully.',
        ),
      ),
    );
  }

  Future<void> _previewDocument(
    BuildContext context,
    dynamic controller,
    String documentId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = await controller.getCustomerDocumentDownloadUrl(documentId);
    if (!context.mounted || url.trim().isEmpty) {
      return;
    }
    final opened = await openPlatformUrl(url);
    if (!context.mounted) {
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
  }

  Future<void> _copyLink(BuildContext context, String documentId) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = await ApiService.getDocumentDownloadUrl(documentId);
    if (!context.mounted) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(
      const SnackBar(content: Text('Download link copied for this document.')),
    );
  }
}

class _RequiredDoc {
  const _RequiredDoc({required this.type, required this.label});

  final String type;
  final String label;
}

IconData _docIcon(String? fileName) {
  final lower = (fileName ?? '').toLowerCase();
  if (lower.endsWith('.pdf')) {
    return Icons.picture_as_pdf_outlined;
  }
  if (lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp')) {
    return Icons.image_outlined;
  }
  return Icons.description_outlined;
}

Color _statusColor(String? rawStatus) {
  switch ((rawStatus ?? '').toUpperCase()) {
    case 'APPROVED':
    case 'VALIDATED':
    case 'VERIFIED':
      return Colors.green.shade700;
    case 'REJECTED':
      return Colors.red.shade700;
    case 'PENDING':
    default:
      return Colors.orange.shade700;
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
      .map(
        (part) =>
            part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _formatDate(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) {
    return 'No date';
  }
  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return 'No date';
  }
  final local = parsed.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
