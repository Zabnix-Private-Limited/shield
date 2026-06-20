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
  });

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
  ];
}

final List<Document> dummyDocuments = [
  Document(
    id: '1',
    uuid: 'doc-001',
    customerId: '1',
    fileName: 'Prescription_2026_06_15.pdf',
    storagePath: '/documents/customers/1/prescriptions/1.pdf',
    fileSize: 154321,
    mimeType: 'application/pdf',
    type: DocumentType.prescription,
    status: DocumentStatus.approved,
    uploadedBy: 'pharmacy-1',
    uploadedAt: DateTime(2026, 6, 15, 10, 30),
    processedAt: DateTime(2026, 6, 15, 10, 45),
  ),
  Document(
    id: '2',
    uuid: 'doc-002',
    customerId: '1',
    fileName: 'Lab_Report_CBC_2026_06_18.pdf',
    storagePath: '/documents/customers/1/lab_reports/2.pdf',
    fileSize: 234567,
    mimeType: 'application/pdf',
    type: DocumentType.labReport,
    status: DocumentStatus.validated,
    uploadedBy: 'lab-1',
    uploadedAt: DateTime(2026, 6, 18, 14, 20),
    processedAt: DateTime(2026, 6, 18, 14, 35),
  ),
  Document(
    id: '3',
    uuid: 'doc-003',
    customerId: '1',
    fileName: 'Dental_Xray_2026_06_12.jpg',
    storagePath: '/documents/customers/1/dental/3.jpg',
    fileSize: 1234567,
    mimeType: 'image/jpeg',
    type: DocumentType.dentalRecord,
    status: DocumentStatus.processing,
    uploadedBy: 'dental-1',
    uploadedAt: DateTime(2026, 6, 12, 9, 15),
  ),
  Document(
    id: '4',
    uuid: 'doc-004',
    customerId: '1',
    fileName: 'Invoice_Pharmacy_2026_06_19.pdf',
    storagePath: '/documents/customers/1/invoices/4.pdf',
    fileSize: 87654,
    mimeType: 'application/pdf',
    type: DocumentType.invoice,
    status: DocumentStatus.classified,
    uploadedBy: 'pharmacy-1',
    uploadedAt: DateTime(2026, 6, 19, 16, 45),
  ),
];
