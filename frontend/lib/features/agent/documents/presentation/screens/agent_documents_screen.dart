import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/services/platform_file_actions.dart';
import '../../../../../shared/utils/prescription_file_picker.dart';
import '../../../shared/presentation/controllers/agent_portal_provider.dart';
import '../../../shared/presentation/widgets/agent_design_system.dart';
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
  String? _activeDocumentId;
  _DocumentAction? _activeDocumentAction;

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

    final docs =
        controller.customerDocuments.where((doc) {
          final status = (doc['status'] ?? '').toString().toUpperCase();
          final matchesFilter = _filter == 'ALL' || status == _filter;
          final combined =
              '${doc['fileName'] ?? ''} ${doc['documentType'] ?? ''} ${doc['status'] ?? ''}'
                  .toLowerCase();
          final matchesQuery = combined.contains(_query.toLowerCase());
          return matchesFilter && matchesQuery;
        }).toList()..sort((a, b) {
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

    if (controller.isLoading && controller.workspace.isEmpty) {
      return _buildWorkspaceLoadingState();
    }

    if ((controller.error ?? '').trim().isNotEmpty &&
        controller.workspace.isEmpty) {
      return _buildWorkspaceErrorState(controller.error!);
    }

    final bodyHeight = (MediaQuery.sizeOf(context).height - 220).clamp(
      360.0,
      1200.0,
    );

    return Card(
      child: Padding(
        padding: AgentUi.panelPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AgentSectionHeader(
              title: 'Documents',
              description:
                  'This customer-first document flow now behaves more like a lightweight DMS: required files, status badges, verification states, sorting, and quick preview actions.',
            ),
            AgentUi.gapH(AgentUi.space16),
            SizedBox(
              height: bodyHeight,
              child: LayoutBuilder(
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
                    return ListView(
                      children: [left, AgentUi.gapH(AgentUi.space16), right],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 320,
                        child: SingleChildScrollView(child: left),
                      ),
                      AgentUi.gapW(AgentUi.space16),
                      Expanded(child: SingleChildScrollView(child: right)),
                    ],
                  );
                },
              ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text(doc.label)),
                      AgentGhostButton(
                        onPressed: () =>
                            setState(() => _documentType = doc.type),
                        label: _documentType == doc.type
                            ? 'Selected'
                            : 'Choose',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: AgentUi.space8,
            runSpacing: AgentUi.space8,
            children: [
              AgentPrimaryButton(
                onPressed: customerId == null || controller.isSaving
                    ? null
                    : () => _uploadDocument(
                        controller,
                        customerId: customerId,
                        documentType: _documentType,
                        replaceExisting: false,
                      ),
                icon: const Icon(Icons.upload_file_outlined),
                label: controller.isSaving ? 'Uploading...' : 'Upload',
                isLoading: controller.isSaving,
              ),
              AgentSecondaryButton(
                onPressed: customerId == null || controller.isSaving
                    ? null
                    : () => _uploadDocument(
                        controller,
                        customerId: customerId,
                        documentType: _documentType,
                        replaceExisting: true,
                      ),
                icon: const Icon(Icons.refresh_outlined),
                label: 'Replace',
              ),
              if (customerId == null)
                AgentGhostButton(
                  onPressed: () => context.go('/portal/agent/customers'),
                  icon: const Icon(Icons.people_alt_outlined),
                  label: 'Open Customers',
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
    final hasCustomer = controller.selectedCustomerId != null;
    final hasFilters = _query.trim().isNotEmpty || _filter != 'ALL';

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
                  DropdownMenuItem(
                    value: 'VALIDATED',
                    child: Text('Validated'),
                  ),
                  DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                ],
                onChanged: (value) => setState(() => _filter = value ?? 'ALL'),
              ),
              DropdownButton<String>(
                value: _sort,
                items: const [
                  DropdownMenuItem(
                    value: 'NEWEST',
                    child: Text('Newest first'),
                  ),
                  DropdownMenuItem(
                    value: 'OLDEST',
                    child: Text('Oldest first'),
                  ),
                ],
                onChanged: (value) => setState(() => _sort = value ?? 'NEWEST'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasCustomer)
            AgentEmptyState(
              icon: Icons.people_alt_outlined,
              title: 'Choose a customer first',
              message:
                  'Open the customer workspace before previewing, downloading, or replacing documents so SHIELD can anchor the file timeline to one member.',
              actionLabel: 'Open Customers',
              onAction: () => context.go('/portal/agent/customers'),
              secondaryActionLabel: 'Refresh',
              onSecondaryAction: () =>
                  ref.read(agentPortalControllerProvider).refreshWorkspace(),
            )
          else if (controller.isCustomerLoading &&
              controller.selectedCustomerWorkspace.isEmpty)
            const AgentPanelCard(
              title: 'Loading Documents',
              subtitle:
                  'Fetching the selected customer document timeline and verification status.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading customer documents...'),
                ],
              ),
            )
          else if ((controller.error ?? '').trim().isNotEmpty &&
              controller.selectedCustomerWorkspace.isEmpty)
            AgentErrorState(
              title: 'We could not load this customer workspace',
              message: _resolveDocumentError(
                controller.error!,
                fallback:
                    'The selected customer documents could not be loaded right now.',
              ),
              onRetry: () => ref
                  .read(agentPortalControllerProvider)
                  .selectCustomer(controller.selectedCustomerId!),
            )
          else if (docs.isEmpty)
            AgentEmptyState(
              icon: hasFilters
                  ? Icons.filter_alt_off_outlined
                  : Icons.folder_copy_outlined,
              title: hasFilters
                  ? 'No documents match these filters'
                  : 'No documents found',
              message: hasFilters
                  ? 'Try clearing the active search or status filter to bring back the customer document timeline.'
                  : 'Upload the first required file to start the document timeline for this customer.',
              actionLabel: hasFilters ? 'Clear Filters' : 'Upload Document',
              onAction: hasFilters
                  ? _clearFilters
                  : () => setState(() => _documentType = 'ID_PROOF'),
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
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
                          onPressed:
                              _isDocumentActionBusy(doc['id']?.toString() ?? '')
                              ? null
                              : () => _previewDocument(
                                  context,
                                  controller,
                                  doc['id']?.toString() ?? '',
                                ),
                          icon: _buildDocumentActionIcon(
                            doc['id']?.toString() ?? '',
                            _DocumentAction.preview,
                            Icons.visibility_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Download',
                          onPressed:
                              _isDocumentActionBusy(doc['id']?.toString() ?? '')
                              ? null
                              : () =>
                                    _downloadDocument(context, controller, doc),
                          icon: _buildDocumentActionIcon(
                            doc['id']?.toString() ?? '',
                            _DocumentAction.download,
                            Icons.download_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy link',
                          onPressed:
                              _isDocumentActionBusy(doc['id']?.toString() ?? '')
                              ? null
                              : () => _copyLink(context, controller, doc),
                          icon: _buildDocumentActionIcon(
                            doc['id']?.toString() ?? '',
                            _DocumentAction.copy,
                            Icons.link_outlined,
                          ),
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
    try {
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
      _showMessage(
        replaceExisting
            ? 'Document replacement uploaded successfully.'
            : 'Document uploaded successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(
        _resolveDocumentError(
          error,
          fallback: 'We could not upload this document right now.',
        ),
      );
    }
  }

  Future<void> _previewDocument(
    BuildContext context,
    dynamic controller,
    String documentId,
  ) async {
    await _runDocumentAction(
      documentId: documentId,
      action: _DocumentAction.preview,
      operation: () async {
        final url = await _resolveDocumentUrl(controller, documentId);
        final opened = await openPlatformUrl(url);
        if (!opened) {
          throw const _DocumentActionException(
            'The document is ready, but opening it is not supported on this device.',
          );
        }
      },
      successMessage: 'Document opened in a new tab.',
      failureFallback: 'We could not open that document right now.',
    );
  }

  Future<void> _downloadDocument(
    BuildContext context,
    dynamic controller,
    Map<String, dynamic> document,
  ) async {
    final documentId = document['id']?.toString() ?? '';
    await _runDocumentAction(
      documentId: documentId,
      action: _DocumentAction.download,
      operation: () async {
        final url = await _resolveDocumentUrl(controller, documentId);
        final downloaded = await downloadPlatformUrl(
          url,
          fileName: document['fileName']?.toString(),
        );
        if (!downloaded) {
          throw const _DocumentActionException(
            'The document is ready, but automatic download is not available on this device.',
          );
        }
      },
      successMessage: 'Document download started.',
      failureFallback: 'We could not download that document right now.',
    );
  }

  Future<void> _copyLink(
    BuildContext context,
    dynamic controller,
    Map<String, dynamic> document,
  ) async {
    final documentId = document['id']?.toString() ?? '';
    await _runDocumentAction(
      documentId: documentId,
      action: _DocumentAction.copy,
      operation: () async {
        final url = await _resolveDocumentUrl(controller, documentId);
        await Clipboard.setData(ClipboardData(text: url));
      },
      successMessage: 'Download link copied for this document.',
      failureFallback: 'We could not copy the document link right now.',
    );
  }

  Widget _buildWorkspaceLoadingState() {
    return const AgentPanelCard(
      title: 'Documents',
      subtitle:
          'Loading the document workspace so uploads, verification states, and customer history stay synchronized.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading document workspace...'),
        ],
      ),
    );
  }

  Widget _buildWorkspaceErrorState(String message) {
    return AgentPanelCard(
      title: 'Documents Unavailable',
      subtitle:
          'The document workspace could not be loaded, so SHIELD is showing a recoverable state instead of a dead-end panel.',
      child: AgentErrorState(
        title: 'We could not load the document workflow',
        message: _resolveDocumentError(
          message,
          fallback: 'The document workspace could not be loaded right now.',
        ),
        onRetry: () =>
            ref.read(agentPortalControllerProvider).refreshWorkspace(),
      ),
    );
  }

  Future<void> _runDocumentAction({
    required String documentId,
    required _DocumentAction action,
    required Future<void> Function() operation,
    required String successMessage,
    required String failureFallback,
  }) async {
    if (documentId.trim().isEmpty) {
      _showMessage(failureFallback);
      return;
    }
    setState(() {
      _activeDocumentId = documentId;
      _activeDocumentAction = action;
    });
    try {
      await operation();
      if (!mounted) {
        return;
      }
      _showMessage(successMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_resolveDocumentError(error, fallback: failureFallback));
    } finally {
      if (mounted) {
        setState(() {
          _activeDocumentId = null;
          _activeDocumentAction = null;
        });
      }
    }
  }

  Future<String> _resolveDocumentUrl(
    dynamic controller,
    String documentId,
  ) async {
    final url =
        await controller.getCustomerDocumentDownloadUrl(documentId) as String;
    if (url.trim().isEmpty) {
      throw const _DocumentActionException('Document link unavailable.');
    }
    return url;
  }

  bool _isDocumentActionBusy(String documentId) =>
      _activeDocumentId == documentId && _activeDocumentAction != null;

  Widget _buildDocumentActionIcon(
    String documentId,
    _DocumentAction action,
    IconData icon,
  ) {
    if (_activeDocumentId == documentId && _activeDocumentAction == action) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(icon);
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _filter = 'ALL';
      _sort = 'NEWEST';
    });
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RequiredDoc {
  const _RequiredDoc({required this.type, required this.label});

  final String type;
  final String label;
}

enum _DocumentAction { preview, download, copy }

class _DocumentActionException implements Exception {
  const _DocumentActionException(this.message);

  final String message;

  @override
  String toString() => message;
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
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
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

String _resolveDocumentError(Object error, {required String fallback}) {
  final message = error.toString().trim();
  final lowered = message.toLowerCase();
  if (error is _DocumentActionException) {
    return error.message;
  }
  if (lowered.contains('403') || lowered.contains('forbidden')) {
    return 'Your current SHIELD role does not have access to this document action yet.';
  }
  if (lowered.contains('404') || lowered.contains('not found')) {
    return 'This document is no longer available from the backend.';
  }
  if (lowered.contains('network') || lowered.contains('socket')) {
    return 'The document service could not be reached because the network connection is unavailable.';
  }
  return message.isEmpty ? fallback : message;
}
