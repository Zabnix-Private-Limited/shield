class PharmacyPaymentRequestModel {
  final String id;
  final String uuid;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerCode;
  final String walletId;
  final double amount;
  final String paymentChannel; // 'BANK_TRANSFER' | 'UPI' | 'PAY_AT_PHARMACY' | 'PAID_THROUGH_AGENT'
  final String referenceNumber;
  final String? proofUrl;
  final String status; // 'PENDING' | 'APPROVED' | 'REJECTED'
  final Map<String, dynamic>? destinationSnapshot;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const PharmacyPaymentRequestModel({
    required this.id,
    required this.uuid,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerCode,
    required this.walletId,
    required this.amount,
    required this.paymentChannel,
    required this.referenceNumber,
    this.proofUrl,
    required this.status,
    this.destinationSnapshot,
    this.rejectionReason,
    this.reviewedAt,
    this.createdAt,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  factory PharmacyPaymentRequestModel.fromJson(Map<String, dynamic> json) {
    return PharmacyPaymentRequestModel(
      id: (json['id'] ?? '').toString(),
      uuid: (json['uuid'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? 'Customer').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      customerCode: (json['customerCode'] ?? '').toString(),
      walletId: (json['walletId'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentChannel: (json['paymentChannel'] ?? 'BANK_TRANSFER').toString(),
      referenceNumber: (json['referenceNumber'] ?? '').toString(),
      proofUrl: json['proofUrl']?.toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      destinationSnapshot: json['destinationSnapshot'] as Map<String, dynamic>?,
      rejectionReason: json['rejectionReason']?.toString(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
