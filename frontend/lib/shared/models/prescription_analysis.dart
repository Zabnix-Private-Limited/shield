import 'package:equatable/equatable.dart';

class PrescriptionAnalysis extends Equatable {
  final String documentId;
  final String fileName;
  final String reviewStatus;
  final double overallConfidence;
  final double extractionConfidence;
  final String? extractedText;
  final PrescriptionStructuredData structuredData;
  final List<PrescriptionMedicineMatch> medicineMatches;
  final List<PrescriptionCartItem> cartPrefill;
  final List<PrescriptionPipelineStep> steps;

  const PrescriptionAnalysis({
    required this.documentId,
    required this.fileName,
    required this.reviewStatus,
    required this.overallConfidence,
    required this.extractionConfidence,
    required this.structuredData,
    required this.medicineMatches,
    required this.cartPrefill,
    required this.steps,
    this.extractedText,
  });

  factory PrescriptionAnalysis.fromJson(Map<String, dynamic> json) {
    final structured = Map<String, dynamic>.from(
      json['structuredJson'] as Map? ?? const <String, dynamic>{},
    );
    return PrescriptionAnalysis(
      documentId: json['documentId'].toString(),
      fileName: (json['fileName'] ?? 'Prescription').toString(),
      reviewStatus: (json['reviewStatus'] ?? 'PENDING_PHARMACIST_APPROVAL')
          .toString(),
      overallConfidence:
          double.tryParse((json['overallConfidence'] ?? 0).toString()) ?? 0,
      extractionConfidence:
          double.tryParse((json['extractionConfidence'] ?? 0).toString()) ?? 0,
      extractedText: json['extractedText']?.toString(),
      structuredData: PrescriptionStructuredData.fromJson(structured),
      medicineMatches:
          (json['medicineMatches'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .map(
                (item) => PrescriptionMedicineMatch.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
      cartPrefill: (json['cartPrefill'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) =>
                PrescriptionCartItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => PrescriptionPipelineStep.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  bool get needsReview => reviewStatus != 'APPROVED';

  @override
  List<Object?> get props => [
    documentId,
    fileName,
    reviewStatus,
    overallConfidence,
    extractionConfidence,
    extractedText,
    structuredData,
    medicineMatches,
    cartPrefill,
    steps,
  ];
}

class PrescriptionStructuredData extends Equatable {
  final String patient;
  final String doctor;
  final String date;
  final List<PrescriptionMedicineItem> medicines;

  const PrescriptionStructuredData({
    required this.patient,
    required this.doctor,
    required this.date,
    required this.medicines,
  });

  factory PrescriptionStructuredData.fromJson(Map<String, dynamic> json) {
    return PrescriptionStructuredData(
      patient: (json['patient'] ?? 'Customer').toString(),
      doctor: (json['doctor'] ?? 'Doctor unavailable').toString(),
      date: (json['date'] ?? '').toString(),
      medicines: (json['medicines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => PrescriptionMedicineItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [patient, doctor, date, medicines];
}

class PrescriptionMedicineItem extends Equatable {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;

  const PrescriptionMedicineItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
  });

  factory PrescriptionMedicineItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicineItem(
      name: (json['name'] ?? 'Medicine').toString(),
      dosage: (json['dosage'] ?? 'As directed').toString(),
      frequency: (json['frequency'] ?? 'As directed').toString(),
      duration: (json['duration'] ?? 'Not specified').toString(),
    );
  }

  @override
  List<Object?> get props => [name, dosage, frequency, duration];
}

class PrescriptionMatchCandidate extends Equatable {
  final String productId;
  final String productName;
  final String? brand;
  final double confidence;

  const PrescriptionMatchCandidate({
    required this.productId,
    required this.productName,
    required this.confidence,
    this.brand,
  });

  factory PrescriptionMatchCandidate.fromJson(Map<String, dynamic> json) {
    return PrescriptionMatchCandidate(
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? 'Product').toString(),
      brand: json['brand']?.toString(),
      confidence: double.tryParse((json['confidence'] ?? 0).toString()) ?? 0,
    );
  }

  @override
  List<Object?> get props => [productId, productName, brand, confidence];
}

class PrescriptionMedicineMatch extends Equatable {
  final String rawName;
  final String dosage;
  final String frequency;
  final String duration;
  final String status;
  final double confidence;
  final String? matchedProductId;
  final String? matchedProductName;
  final String? matchedBrand;
  final List<PrescriptionMatchCandidate> candidates;

  const PrescriptionMedicineMatch({
    required this.rawName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.status,
    required this.confidence,
    required this.candidates,
    this.matchedProductId,
    this.matchedProductName,
    this.matchedBrand,
  });

  factory PrescriptionMedicineMatch.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicineMatch(
      rawName: (json['rawName'] ?? 'Medicine').toString(),
      dosage: (json['dosage'] ?? 'As directed').toString(),
      frequency: (json['frequency'] ?? 'As directed').toString(),
      duration: (json['duration'] ?? 'Not specified').toString(),
      status: (json['status'] ?? 'UNMATCHED').toString(),
      confidence: double.tryParse((json['confidence'] ?? 0).toString()) ?? 0,
      matchedProductId: json['matchedProductId']?.toString(),
      matchedProductName: json['matchedProductName']?.toString(),
      matchedBrand: json['matchedBrand']?.toString(),
      candidates: (json['candidates'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => PrescriptionMatchCandidate.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  bool get isMatched => status == 'MATCHED';

  @override
  List<Object?> get props => [
    rawName,
    dosage,
    frequency,
    duration,
    status,
    confidence,
    matchedProductId,
    matchedProductName,
    matchedBrand,
    candidates,
  ];
}

class PrescriptionCartItem extends Equatable {
  final String productId;
  final String productName;
  final String? brand;
  final int quantity;
  final String dosage;
  final String frequency;
  final String duration;
  final double confidence;
  final bool needsReview;

  const PrescriptionCartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.confidence,
    required this.needsReview,
    this.brand,
  });

  factory PrescriptionCartItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionCartItem(
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? 'Product').toString(),
      brand: json['brand']?.toString(),
      quantity: int.tryParse((json['quantity'] ?? 1).toString()) ?? 1,
      dosage: (json['dosage'] ?? 'As directed').toString(),
      frequency: (json['frequency'] ?? 'As directed').toString(),
      duration: (json['duration'] ?? 'Not specified').toString(),
      confidence: double.tryParse((json['confidence'] ?? 0).toString()) ?? 0,
      needsReview: json['needsReview'] == true,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    brand,
    quantity,
    dosage,
    frequency,
    duration,
    confidence,
    needsReview,
  ];
}

class PrescriptionPipelineStep extends Equatable {
  final String key;
  final String label;
  final String status;

  const PrescriptionPipelineStep({
    required this.key,
    required this.label,
    required this.status,
  });

  factory PrescriptionPipelineStep.fromJson(Map<String, dynamic> json) {
    return PrescriptionPipelineStep(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
    );
  }

  bool get isDone => status == 'done';

  @override
  List<Object?> get props => [key, label, status];
}
