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
  final double availableQuantity;
  final double fulfillQuantity;
  final double unitPrice;
  final double lineTotal;
  final String stockStatus; // FULL_STOCK | LOW_STOCK | OUT_OF_STOCK
  final String decisionStatus; // APPROVED | PARTIAL | REJECTED | SUBSTITUTED | AWAITING_CUSTOMER_CONFIRMATION
  final String? substituteName;
  final double? substituteUnitPrice;
  final String? decisionReason;

  const PharmacyOrderItem({
    required this.id,
    this.productId,
    required this.name,
    required this.quantity,
    required this.availableQuantity,
    required this.fulfillQuantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.stockStatus,
    required this.decisionStatus,
    this.substituteName,
    this.substituteUnitPrice,
    this.decisionReason,
  });

  factory PharmacyOrderItem.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final reqQty = (json['quantity'] as num?)?.toDouble() ?? 1.0;
    final fulQty = (json['fulfillQuantity'] as num?)?.toDouble() ??
        (meta['fulfillQuantity'] as num?)?.toDouble() ??
        reqQty;
    final availQty = (json['availableQuantity'] as num?)?.toDouble() ??
        (meta['availableQuantity'] as num?)?.toDouble() ??
        reqQty;

    String stock = (json['stockStatus'] ?? meta['stockStatus'] ?? '').toString();
    if (stock.isEmpty) {
      if (availQty >= reqQty) {
        stock = 'FULL_STOCK';
      } else if (availQty > 0) {
        stock = 'LOW_STOCK';
      } else {
        stock = 'OUT_OF_STOCK';
      }
    }

    final decision = (json['decisionStatus'] ?? meta['decisionStatus'] ?? 'PENDING').toString();
    final isRejected = decision.toUpperCase() == 'REJECTED';

    final subName = json['substituteName']?.toString() ?? meta['substituteName']?.toString();
    final subPrice = (json['substituteUnitPrice'] as num?)?.toDouble() ??
        (meta['substituteUnitPrice'] as num?)?.toDouble();
    final reason = json['decisionReason']?.toString() ?? meta['decisionReason']?.toString();
    final unitPrice = (json['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final authPrice = subPrice ?? unitPrice;

    final lineTotal = isRejected
        ? 0.0
        : ((json['lineTotal'] as num?)?.toDouble() ??
            (json['totalPrice'] as num?)?.toDouble() ??
            (fulQty * authPrice));

    return PharmacyOrderItem(
      id: (json['id'] ?? '').toString(),
      productId: json['productId']?.toString(),
      name: (json['name'] ?? 'Product').toString(),
      quantity: reqQty,
      availableQuantity: availQty,
      fulfillQuantity: fulQty,
      unitPrice: unitPrice,
      lineTotal: lineTotal,
      stockStatus: stock,
      decisionStatus: decision,
      substituteName: subName,
      substituteUnitPrice: subPrice,
      decisionReason: reason,
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
  final String? pharmacistNotes;
  final bool isChronic;
  final String? invoiceUrl;
  final String? invoiceFileName;
  final DateTime? invoiceSentAt;
  final bool customerConfirmationRequested;
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
    this.pharmacistNotes,
    this.isChronic = false,
    this.invoiceUrl,
    this.invoiceFileName,
    this.invoiceSentAt,
    this.customerConfirmationRequested = false,
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

    final billingSnap = json['billingSnapshot'] is Map<String, dynamic>
        ? json['billingSnapshot'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return PharmacyOrderModel(
      id: (json['id'] ?? '').toString(),
      uuid: (json['uuid'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? json['invoiceNumber'] ?? '').toString(),
      status: (json['status'] ?? json['orderStatus'] ?? 'PLACED').toString(),
      paymentStatus: (json['paymentStatus'] ?? 'PENDING').toString(),
      orderSource: (json['orderSource'] ?? json['purchaseKind'] ?? 'MANUAL_ITEMS').toString(),
      fulfillmentPreference: json['fulfillmentPreference']?.toString(),
      customer: json['customer'] != null
          ? PharmacyOrderCustomer.fromJson(
              json['customer'] as Map<String, dynamic>,
            )
          : null,
      deliveryAddress: json['deliveryAddress']?.toString(),
      customerNotes: json['customerNotes']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      pharmacistNotes: billingSnap['pharmacistNotes']?.toString() ?? json['pharmacistNotes']?.toString(),
      isChronic: billingSnap['isChronic'] == true || json['isChronic'] == true,
      invoiceUrl: billingSnap['invoiceUrl']?.toString() ?? json['invoiceUrl']?.toString(),
      invoiceFileName: billingSnap['invoiceFileName']?.toString() ?? json['invoiceFileName']?.toString(),
      invoiceSentAt: billingSnap['invoiceSentAt'] != null
          ? DateTime.tryParse(billingSnap['invoiceSentAt'].toString())
          : null,
      customerConfirmationRequested:
          billingSnap['customerConfirmationRequested'] == true ||
          json['customerConfirmationRequested'] == true,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      payableAmount: (json['payableAmount'] as num?)?.toDouble() ?? 0.0,
      submittedAt: parsedDate,
      items: (json['items'] as List? ?? json['purchaseItems'] as List? ?? const <dynamic>[])
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
  final int chronicCount;
  final int totalCount;

  const PharmacyOrdersSummary({
    required this.newCount,
    required this.acceptedCount,
    required this.preparingCount,
    required this.readyCount,
    required this.deliveryCount,
    required this.completedCount,
    required this.cancelledCount,
    this.chronicCount = 0,
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
      chronicCount: (json['chronicCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    );
  }
}
