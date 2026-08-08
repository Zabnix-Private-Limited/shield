import 'package:equatable/equatable.dart';

enum DocumentType { prescription, labReport, dentalRecord, invoice, other }

enum DocumentStatus {
  uploaded,
  processing,
  classified,
  extracted,
  validated,
  approved,
  rejected,
}

extension DocumentTypeCustomerLabel on DocumentType {
  String get typeLabel => switch (this) {
    DocumentType.prescription => 'Prescription',
    DocumentType.labReport => 'Lab report',
    DocumentType.dentalRecord => 'Dental record',
    DocumentType.invoice => 'Invoice',
    DocumentType.other => 'Other document',
  };
}

class Document extends Equatable {
  final String id;
  final String uuid;
  final String customerId;
  final String fileName;
  final String storagePath;
  final int? fileSize;
  final String? mimeType;
  final DocumentType? type;
  final DocumentStatus status;
  final String? uploadedBy;
  final DateTime uploadedAt;
  final DateTime? processedAt;
  final String? extractionText;
  final double? extractionConfidence;

  const Document({
    required this.id,
    required this.uuid,
    required this.customerId,
    required this.fileName,
    required this.storagePath,
    this.fileSize,
    this.mimeType,
    this.type,
    required this.status,
    this.uploadedBy,
    required this.uploadedAt,
    this.processedAt,
    this.extractionText,
    this.extractionConfidence,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    final extractions =
        (json['documentExtractions'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    final processingLogs =
        (json['documentProcessingLogs'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    final latestExtraction = extractions.isEmpty ? null : extractions.last;
    final latestProcessingLog = processingLogs.isEmpty
        ? null
        : processingLogs.last;

    DocumentType parseType(String? value) {
      switch ((value ?? '').toUpperCase()) {
        case 'PRESCRIPTION':
          return DocumentType.prescription;
        case 'LAB_REPORT':
          return DocumentType.labReport;
        case 'DENTAL_REPORT':
        case 'DENTAL_RECORD':
          return DocumentType.dentalRecord;
        case 'INVOICE':
        case 'PHARMACY_BILL':
          return DocumentType.invoice;
        default:
          return DocumentType.other;
      }
    }

    DocumentStatus parseStatus(String? value) {
      switch ((value ?? '').toUpperCase()) {
        case 'PROCESSING':
          return DocumentStatus.processing;
        case 'CLASSIFIED':
          return DocumentStatus.classified;
        case 'EXTRACTED':
          return DocumentStatus.extracted;
        case 'VALIDATED':
          return DocumentStatus.validated;
        case 'APPROVED':
          return DocumentStatus.approved;
        case 'REJECTED':
          return DocumentStatus.rejected;
        case 'UPLOADED':
          return DocumentStatus.uploaded;
        default:
          return DocumentStatus.processing;
      }
    }

    return Document(
      id: json['id'].toString(),
      uuid: (json['uuid'] ?? 'document-${json['id']}').toString(),
      customerId: (json['customerId'] ?? json['customer_id'] ?? '').toString(),
      fileName: (json['fileName'] ?? json['file_name'] ?? 'document')
          .toString(),
      storagePath: (json['storagePath'] ?? json['storage_path'] ?? '')
          .toString(),
      fileSize: int.tryParse(
        (json['fileSize'] ?? json['file_size'] ?? '').toString(),
      ),
      mimeType: (json['mimeType'] ?? json['mime_type'])?.toString(),
      type: parseType(
        (json['documentType'] ?? json['document_type'])?.toString(),
      ),
      status: parseStatus((json['status'] ?? 'PROCESSING').toString()),
      uploadedBy: (json['uploadedBy'] ?? json['uploaded_by'])?.toString(),
      uploadedAt:
          DateTime.tryParse(
            (json['createdAt'] ?? json['created_at']).toString(),
          ) ??
          DateTime.now(),
      processedAt: DateTime.tryParse(
        (json['processedAt'] ??
                json['processed_at'] ??
                latestProcessingLog?['processedAt'] ??
                latestProcessingLog?['processed_at'] ??
                '')
            .toString(),
      ),
      extractionText:
          (latestExtraction?['extractedText'] ??
                  latestExtraction?['extracted_text'])
              ?.toString(),
      extractionConfidence: double.tryParse(
        (latestExtraction?['confidenceScore'] ??
                latestExtraction?['confidence_score'] ??
                '')
            .toString(),
      ),
    );
  }

  String get typeLabel => type?.typeLabel ?? 'Document';

  String get statusLabel => switch (status) {
    DocumentStatus.uploaded => 'Uploaded',
    DocumentStatus.processing => 'Processing',
    DocumentStatus.classified => 'Classified',
    DocumentStatus.extracted => 'Extracted',
    DocumentStatus.validated => 'Validated',
    DocumentStatus.approved => 'Approved',
    DocumentStatus.rejected => 'Rejected',
  };

  String? get extractionPreview {
    final text = extractionText?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 96) {
      return compact;
    }
    return '${compact.substring(0, 93)}...';
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    customerId,
    fileName,
    storagePath,
    fileSize,
    mimeType,
    type,
    status,
    uploadedBy,
    uploadedAt,
    processedAt,
    extractionText,
    extractionConfidence,
  ];
}
