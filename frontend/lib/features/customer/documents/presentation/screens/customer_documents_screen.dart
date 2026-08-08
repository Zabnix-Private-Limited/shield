import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/models/document.dart';
import '../../../../../shared/services/platform_file_actions.dart';
import '../../../../../shared/utils/prescription_file_picker.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_skeleton.dart';
import '../../../../../shared/widgets/portal_support.dart';
import '../../../shared/widgets/error_card.dart';
import '../customer_documents_controller.dart';

class CustomerDocumentsScreen extends StatefulWidget {
  const CustomerDocumentsScreen({super.key, this.controller});

  final CustomerDocumentsController? controller;

  @override
  State<CustomerDocumentsScreen> createState() =>
      _CustomerDocumentsScreenState();
}

class _CustomerDocumentsScreenState extends State<CustomerDocumentsScreen> {
  late final CustomerDocumentsController _controller;
  late final bool _ownsController;
  final _search = TextEditingController();
  late Future<List<Document>> _documentsFuture;
  var _isUploading = false;
  String? _forcedDocumentType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _forcedDocumentType = GoRouterState.of(
        context,
      ).uri.queryParameters['type'];
    } catch (_) {
      _forcedDocumentType = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CustomerDocumentsController();
    _loadDocuments();
  }

  @override
  void dispose() {
    _search.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _loadDocuments() {
    setState(() {
      _documentsFuture = _controller.load().then((_) {
        if (_controller.error != null) throw _controller.error!;
        return _controller.documents;
      });
    });
  }

  Future<void> _openDocument(Document document) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await _controller.viewerUrl(document);
      if (url.trim().isEmpty || !await openPlatformUrl(url)) {
        throw StateError('Document link unavailable');
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('We could not open that document right now.'),
          ),
        );
      }
    }
  }

  Future<void> _downloadDocument(Document document) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await _controller.viewerUrl(document);
      if (url.trim().isEmpty ||
          !await downloadPlatformUrl(url, fileName: document.fileName)) {
        throw StateError('Document link unavailable');
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('We could not download that document right now.'),
          ),
        );
      }
    }
  }

  Future<void> _uploadDocument(DocumentType type) async {
    final picked = await pickPrescriptionFile();
    if (!mounted || picked == null) return;

    setState(() => _isUploading = true);
    try {
      final uploaded = await _controller.upload(
        fileName: picked.name.isEmpty ? 'prescription.pdf' : picked.name,
        documentType: _documentTypeCode(type),
        fileBytes: picked.bytes,
        mimeType: picked.mimeType ?? 'application/pdf',
        fileSize: picked.size <= 0 ? 1024 : picked.size,
      );
      if (!mounted) return;
      if (uploaded == null) throw StateError('Upload could not be completed.');
      _loadDocuments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${type.typeLabel} uploaded and saved to your records.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Prescription upload could not be completed. Please retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _chooseUploadType() async {
    if (_forcedDocumentType?.trim().toUpperCase() == 'PRESCRIPTION') {
      await _uploadDocument(DocumentType.prescription);
      return;
    }
    final type = await showModalBottomSheet<DocumentType>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: DocumentType.values
              .map(
                (type) => ListTile(
                  leading: Icon(_typeIcon(type)),
                  title: Text(type.typeLabel),
                  onTap: () => Navigator.pop(context, type),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (type != null) await _uploadDocument(type);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Document>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPortalSectionSkeleton(
            showHero: true,
            statCards: 2,
            listItems: 5,
          );
        }

        if (snapshot.hasError) {
          return ErrorCard(
            title: 'Documents unavailable',
            message: 'Your document archive could not be loaded.',
            onRetry: () => setState(_loadDocuments),
          );
        }

        final documents = snapshot.data ?? const <Document>[];
        final visible = _controller.visible;
        final approvedCount = documents
            .where((document) => document.status == DocumentStatus.approved)
            .length;
        final processingCount = documents
            .where((document) => document.status == DocumentStatus.processing)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.shieldBlue, AppColors.shieldNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${documents.length} documents in your archive',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prescriptions, reports, and invoices uploaded through SHIELD appear here with their real archive status.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ArchiveChip(
                        label: '$approvedCount approved',
                        icon: Icons.verified_outlined,
                      ),
                      _ArchiveChip(
                        label: '$processingCount processing',
                        icon: Icons.timelapse_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _chooseUploadType,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(
                      _isUploading ? 'Uploading…' : 'Upload document',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _search,
              onChanged: (value) {
                _controller.setQuery(value);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search documents',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          _controller.setQuery('');
                          setState(() {});
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _controller.selectedType == null,
                    onSelected: (_) =>
                        setState(() => _controller.setType(null)),
                  ),
                  ...DocumentType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(type.typeLabel),
                        selected: _controller.selectedType == type,
                        onSelected: (_) => setState(
                          () => _controller.setType(
                            _controller.selectedType == type ? null : type,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (documents.isEmpty)
              AppCard(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No documents yet', style: AppTypography.h4),
                    SizedBox(height: 8),
                    Text(
                      'Uploaded prescriptions, reports, and invoices will appear here once SHIELD starts receiving them for this customer.',
                      style: AppTypography.body,
                    ),
                  ],
                ),
              )
            else if (visible.isEmpty)
              AppCard(
                child: const Text(
                  'No documents match the selected filter.',
                  style: AppTypography.body,
                ),
              )
            else ...[
              Text('Archive', style: AppTypography.h4),
              const SizedBox(height: 12),
              ...visible.map(
                (document) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => showPortalDetailsSheet(
                      context,
                      title: document.fileName,
                      subtitle:
                          'This ${_statusText(document.status).toLowerCase()} file is visible in the active customer archive.',
                      meta:
                          '${document.typeLabel} • ${_formatDate(document.uploadedAt)}',
                      status: _statusText(document.status),
                      highlights: [
                        'File type: ${document.mimeType ?? 'Unavailable'}',
                        if (document.fileSize != null)
                          'Size: ${document.fileSize} bytes',
                      ],
                      actionText: 'Open secure document',
                      onAction: () => _openDocument(document),
                      secondaryActionText: 'Download',
                      onSecondaryAction: () => _downloadDocument(document),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _typeColor(
                              document.type,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _typeIcon(document.type),
                            color: _typeColor(document.type),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${document.typeLabel} • ${_formatDate(document.uploadedAt)}',
                                style: AppTypography.tiny.copyWith(
                                  color: AppColors.gray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              document.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText(document.status),
                            style: AppTypography.tiny.copyWith(
                              color: _statusColor(document.status),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';

  String _documentTypeCode(DocumentType type) => switch (type) {
    DocumentType.prescription => 'PRESCRIPTION',
    DocumentType.labReport => 'LAB_REPORT',
    DocumentType.dentalRecord => 'DENTAL_RECORD',
    DocumentType.invoice => 'INVOICE',
    DocumentType.other => 'OTHER',
  };

  IconData _typeIcon(DocumentType? type) {
    switch (type) {
      case DocumentType.prescription:
        return Icons.medication_outlined;
      case DocumentType.labReport:
        return Icons.science_outlined;
      case DocumentType.dentalRecord:
        return Icons.medical_services_outlined;
      case DocumentType.invoice:
        return Icons.receipt_long_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _typeColor(DocumentType? type) {
    switch (type) {
      case DocumentType.prescription:
        return AppColors.shieldBlue;
      case DocumentType.labReport:
        return AppColors.shieldGreen;
      case DocumentType.dentalRecord:
        return AppColors.warning;
      case DocumentType.invoice:
        return AppColors.shieldNavy;
      default:
        return AppColors.gray;
    }
  }

  Color _statusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return AppColors.shieldGreen;
      case DocumentStatus.validated:
        return AppColors.shieldLightBlue;
      case DocumentStatus.processing:
        return AppColors.warning;
      case DocumentStatus.rejected:
        return AppColors.error;
      default:
        return AppColors.gray;
    }
  }

  String _statusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return 'Approved';
      case DocumentStatus.validated:
        return 'Validated';
      case DocumentStatus.processing:
        return 'Processing';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.uploaded:
        return 'Uploaded';
      case DocumentStatus.classified:
        return 'Classified';
      case DocumentStatus.extracted:
        return 'Extracted';
    }
  }
}

class _ArchiveChip extends StatelessWidget {
  const _ArchiveChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.small.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
