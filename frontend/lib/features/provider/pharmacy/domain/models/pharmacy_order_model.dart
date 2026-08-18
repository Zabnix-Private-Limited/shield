class PharmacyOrderCustomer {
  final String id;
  final String? customerCode;
  final String fullName;
  final String mobile;
  final String? email;

  const PharmacyOrderCustomer({
    required this.id,
    this.customerCode,
    required this.fullName,
    required this.mobile,
    this.email,
  });

  factory PharmacyOrderCustomer.fromJson(Map<String, dynamic> json) {
    return PharmacyOrderCustomer(
      id: (json['id'] ?? '').toString(),
      customerCode: json['customerCode']?.toString(),
      fullName: (json['fullName'] ?? 'Customer').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      email: json['email']?.toString(),
    );
  }
}

class PharmacyOrderItem {
  final String id;
  final String? productId;
  final String name;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  const PharmacyOrderItem({
    required this.id,
    this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory PharmacyOrderItem.fromJson(Map<String, dynamic> json) {
    return PharmacyOrderItem(
      id: (json['id'] ?? '').toString(),
      productId: json['productId']?.toString(),
      name: (json['name'] ?? 'Product').toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PharmacyOrderModel {
  final String id;
  final String uuid;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String orderSource; // PRESCRIPTION | MANUAL_ITEMS | WELLNESS
  final String? fulfillmentPreference; // HOME_DELIVERY | COLLECT_FROM_PHARMACY | null
  final PharmacyOrderCustomer? customer;
  final String? deliveryAddress;
  final String? customerNotes;
  final String? cancellationReason;
  final double totalAmount;
  final double payableAmount;
  final DateTime submittedAt;
  final List<PharmacyOrderItem> items;
  final Map<String, dynamic>? prescriptionDocument;

  const PharmacyOrderModel({
    required this.id,
    required this.uuid,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.orderSource,
    this.fulfillmentPreference,
    this.customer,
    this.deliveryAddress,
    this.customerNotes,
    this.cancellationReason,
    required this.totalAmount,
    required this.payableAmount,
    required this.submittedAt,
    required this.items,
    this.prescriptionDocument,
  });

  bool get isHomeDelivery => fulfillmentPreference == 'HOME_DELIVERY';
  bool get isPharmacyPickup => fulfillmentPreference == 'COLLECT_FROM_PHARMACY';
  String get displayFulfillment => fulfillmentPreference == 'HOME_DELIVERY'
      ? 'Home Delivery'
      : (fulfillmentPreference == 'COLLECT_FROM_PHARMACY'
          ? 'Pickup from Pharmacy'
          : 'Not specified');
  bool get isPrescription => orderSource == 'PRESCRIPTION';
  bool get isWellness => orderSource == 'WELLNESS';

  factory PharmacyOrderModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['submittedAt'];
    DateTime parsedDate;
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return PharmacyOrderModel(
      id: (json['id'] ?? '').toString(),
      uuid: (json['uuid'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      status: (json['status'] ?? 'PLACED').toString(),
      paymentStatus: (json['paymentStatus'] ?? 'PENDING').toString(),
      orderSource: (json['orderSource'] ?? 'MANUAL_ITEMS').toString(),
      fulfillmentPreference: json['fulfillmentPreference']?.toString(),
      customer: json['customer'] != null
          ? PharmacyOrderCustomer.fromJson(
              json['customer'] as Map<String, dynamic>,
            )
          : null,
      deliveryAddress: json['deliveryAddress']?.toString(),
      customerNotes: json['customerNotes']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      payableAmount: (json['payableAmount'] as num?)?.toDouble() ?? 0.0,
      submittedAt: parsedDate,
      items: (json['items'] as List? ?? const <dynamic>[])
          .map((i) => PharmacyOrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      prescriptionDocument: json['prescriptionDocument'] as Map<String, dynamic>?,
    );
  }
}

class PharmacyOrdersSummary {
  final int newCount;
  final int acceptedCount;
  final int preparingCount;
  final int readyCount;
  final int deliveryCount;
  final int completedCount;
  final int cancelledCount;
  final int totalCount;

  const PharmacyOrdersSummary({
    required this.newCount,
    required this.acceptedCount,
    required this.preparingCount,
    required this.readyCount,
    required this.deliveryCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.totalCount,
  });

  factory PharmacyOrdersSummary.fromJson(Map<String, dynamic> json) {
    return PharmacyOrdersSummary(
      newCount: (json['newCount'] as num?)?.toInt() ?? 0,
      acceptedCount: (json['acceptedCount'] as num?)?.toInt() ?? 0,
      preparingCount: (json['preparingCount'] as num?)?.toInt() ?? 0,
      readyCount: (json['readyCount'] as num?)?.toInt() ?? 0,
      deliveryCount: (json['deliveryCount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      cancelledCount: (json['cancelledCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    );
  }
}
