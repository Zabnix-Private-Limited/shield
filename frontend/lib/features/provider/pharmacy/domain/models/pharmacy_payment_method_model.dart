class PharmacyPaymentMethodModel {
  final String id;
  final String uuid;
  final String methodType; // 'BANK_ACCOUNT' | 'UPI'
  final String? displayLabel;

  // Bank Account fields
  final String? accountHolderName;
  final String? bankName;
  final String? maskedAccountNumber;
  final String? ifscCode;
  final String? branchName;

  // UPI fields
  final String? upiId;
  final String? qrImageUrl;
  final String? qrFileName;

  // State
  final bool isActive;
  final bool isPrimary;
  final DateTime? createdAt;

  const PharmacyPaymentMethodModel({
    required this.id,
    required this.uuid,
    required this.methodType,
    this.displayLabel,
    this.accountHolderName,
    this.bankName,
    this.maskedAccountNumber,
    this.ifscCode,
    this.branchName,
    this.upiId,
    this.qrImageUrl,
    this.qrFileName,
    required this.isActive,
    required this.isPrimary,
    this.createdAt,
  });

  bool get isBankAccount => methodType == 'BANK_ACCOUNT';
  bool get isUpi => methodType == 'UPI';

  factory PharmacyPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PharmacyPaymentMethodModel(
      id: (json['id'] ?? '').toString(),
      uuid: (json['uuid'] ?? '').toString(),
      methodType: (json['methodType'] ?? 'BANK_ACCOUNT').toString(),
      displayLabel: json['displayLabel']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
      bankName: json['bankName']?.toString(),
      maskedAccountNumber: json['maskedAccountNumber']?.toString(),
      ifscCode: json['ifscCode']?.toString(),
      branchName: json['branchName']?.toString(),
      upiId: json['upiId']?.toString(),
      qrImageUrl: json['qrImageUrl']?.toString(),
      qrFileName: json['qrFileName']?.toString(),
      isActive: (json['isActive'] as bool?) ?? true,
      isPrimary: (json['isPrimary'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class PharmacyPaymentDetailsResponse {
  final List<PharmacyPaymentMethodModel> bankAccounts;
  final List<PharmacyPaymentMethodModel> upiMethods;

  const PharmacyPaymentDetailsResponse({
    required this.bankAccounts,
    required this.upiMethods,
  });

  factory PharmacyPaymentDetailsResponse.fromJson(Map<String, dynamic> json) {
    final rawBank = json['bankAccounts'] as List? ?? const [];
    final rawUpi = json['upiMethods'] as List? ?? const [];

    return PharmacyPaymentDetailsResponse(
      bankAccounts: rawBank
          .map((b) => PharmacyPaymentMethodModel.fromJson(b as Map<String, dynamic>))
          .toList(),
      upiMethods: rawUpi
          .map((u) => PharmacyPaymentMethodModel.fromJson(u as Map<String, dynamic>))
          .toList(),
    );
  }
}
