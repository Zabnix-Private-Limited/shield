class CustomerOrderSummary {
  const CustomerOrderSummary({
    required this.invoiceNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.payableAmount,
    required this.purchaseDate,
    required this.itemCount,
    required this.providerName,
  });

  final String invoiceNumber;
  final String orderStatus;
  final String paymentStatus;
  final String payableAmount;
  final DateTime? purchaseDate;
  final int itemCount;
  final String providerName;

  factory CustomerOrderSummary.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] is Map
        ? Map<String, dynamic>.from(json['provider'] as Map)
        : const <String, dynamic>{};
    final items = json['purchaseItems'] is List
        ? json['purchaseItems'] as List
        : const <dynamic>[];
    return CustomerOrderSummary(
      invoiceNumber: json['invoiceNumber']?.toString().trim() ?? '',
      orderStatus: json['orderStatus']?.toString().trim() ?? '',
      paymentStatus: json['paymentStatus']?.toString().trim() ?? '',
      payableAmount:
          json['payableAmount']?.toString() ??
          json['totalAmount']?.toString() ??
          '',
      purchaseDate: DateTime.tryParse(json['purchaseDate']?.toString() ?? ''),
      itemCount: items.length,
      providerName:
          provider['businessName']?.toString().trim() ??
          provider['providerName']?.toString().trim() ??
          provider['name']?.toString().trim() ??
          '',
    );
  }
}
