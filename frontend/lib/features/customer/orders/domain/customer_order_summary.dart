class CustomerOrderSummary {
  const CustomerOrderSummary({
    required this.id,
    required this.invoiceNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.payableAmount,
    required this.purchaseDate,
    required this.itemCount,
    required this.providerName,
    this.orderSource = 'MANUAL_ITEMS',
    this.fulfillmentPreference = 'COLLECT_FROM_PHARMACY',
    this.deliveryAddress,
    this.customerNotes,
    this.prescriptionDocument,
  });

  final String id;
  final String invoiceNumber;
  final String orderStatus;
  final String paymentStatus;
  final String payableAmount;
  final DateTime? purchaseDate;
  final int itemCount;
  final String providerName;
  final String orderSource;
  final String fulfillmentPreference;
  final String? deliveryAddress;
  final String? customerNotes;
  final Map<String, dynamic>? prescriptionDocument;

  factory CustomerOrderSummary.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] is Map
        ? Map<String, dynamic>.from(json['provider'] as Map)
        : json['pharmacy'] is Map
        ? Map<String, dynamic>.from(json['pharmacy'] as Map)
        : const <String, dynamic>{};
    final items = json['items'] is List
        ? json['items'] as List
        : json['purchaseItems'] is List
        ? json['purchaseItems'] as List
        : const <dynamic>[];
    return CustomerOrderSummary(
      id: json['id']?.toString().trim() ?? '',
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
          json['providerName']?.toString().trim() ??
          provider['businessName']?.toString().trim() ??
          provider['providerName']?.toString().trim() ??
          provider['name']?.toString().trim() ??
          '',
      orderSource: json['orderSource']?.toString().trim() ?? 'MANUAL_ITEMS',
      fulfillmentPreference:
          json['fulfillmentPreference']?.toString().trim() ?? 'COLLECT_FROM_PHARMACY',
      deliveryAddress: json['deliveryAddress']?.toString().trim(),
      customerNotes: json['customerNotes']?.toString().trim(),
      prescriptionDocument: json['prescriptionDocument'] is Map
          ? Map<String, dynamic>.from(json['prescriptionDocument'] as Map)
          : null,
    );
  }
}

class CustomerOrderItem {
  const CustomerOrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String name;
  final String quantity;
  final String unitPrice;
  final String lineTotal;

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) =>
      CustomerOrderItem(
        name: json['name']?.toString().trim() ?? 'Product',
        quantity: json['quantity']?.toString() ?? '',
        unitPrice: json['unitPrice']?.toString() ?? '',
        lineTotal: json['lineTotal']?.toString() ?? '',
      );
}

class CustomerOrderDetails extends CustomerOrderSummary {
  const CustomerOrderDetails({
    required super.id,
    required super.invoiceNumber,
    required super.orderStatus,
    required super.paymentStatus,
    required super.payableAmount,
    required super.purchaseDate,
    required super.itemCount,
    required super.providerName,
    super.orderSource,
    super.fulfillmentPreference,
    super.deliveryAddress,
    super.customerNotes,
    super.prescriptionDocument,
    required this.items,
  });

  final List<CustomerOrderItem> items;

  factory CustomerOrderDetails.fromJson(Map<String, dynamic> json) {
    final summary = CustomerOrderSummary.fromJson(json);
    final rawItems = json['items'] is List
        ? json['items'] as List
        : const <dynamic>[];
    return CustomerOrderDetails(
      id: summary.id,
      invoiceNumber: summary.invoiceNumber,
      orderStatus: summary.orderStatus,
      paymentStatus: summary.paymentStatus,
      payableAmount: summary.payableAmount,
      purchaseDate: summary.purchaseDate,
      itemCount: summary.itemCount,
      providerName: summary.providerName,
      orderSource: summary.orderSource,
      fulfillmentPreference: summary.fulfillmentPreference,
      deliveryAddress: summary.deliveryAddress,
      customerNotes: summary.customerNotes,
      prescriptionDocument: summary.prescriptionDocument,
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                CustomerOrderItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}
