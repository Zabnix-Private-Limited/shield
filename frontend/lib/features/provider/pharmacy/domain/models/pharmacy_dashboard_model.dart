class PharmacyDashboardOrdersSummary {
  final int newCount;
  final int preparingCount;
  final int readyCount;
  final int deliveryCount;
  final int completedToday;
  final double orderValueToday;

  const PharmacyDashboardOrdersSummary({
    required this.newCount,
    required this.preparingCount,
    required this.readyCount,
    required this.deliveryCount,
    required this.completedToday,
    required this.orderValueToday,
  });

  factory PharmacyDashboardOrdersSummary.fromJson(Map<String, dynamic> json) {
    return PharmacyDashboardOrdersSummary(
      newCount: (json['new'] as num?)?.toInt() ?? 0,
      preparingCount: (json['preparing'] as num?)?.toInt() ?? 0,
      readyCount: (json['ready'] as num?)?.toInt() ?? 0,
      deliveryCount: (json['delivery'] as num?)?.toInt() ?? 0,
      completedToday: (json['completedToday'] as num?)?.toInt() ?? 0,
      orderValueToday: (json['orderValueToday'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PharmacyDashboardPaymentsSummary {
  final int pendingVerification;
  final int approvedToday;
  final double approvedAmountToday;

  const PharmacyDashboardPaymentsSummary({
    required this.pendingVerification,
    required this.approvedToday,
    required this.approvedAmountToday,
  });

  factory PharmacyDashboardPaymentsSummary.fromJson(Map<String, dynamic> json) {
    return PharmacyDashboardPaymentsSummary(
      pendingVerification: (json['pendingVerification'] as num?)?.toInt() ?? 0,
      approvedToday: (json['approvedToday'] as num?)?.toInt() ?? 0,
      approvedAmountToday: (json['approvedAmountToday'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PharmacyDashboardPaymentConfig {
  final bool bankConfigured;
  final bool upiConfigured;

  const PharmacyDashboardPaymentConfig({
    required this.bankConfigured,
    required this.upiConfigured,
  });

  factory PharmacyDashboardPaymentConfig.fromJson(Map<String, dynamic> json) {
    return PharmacyDashboardPaymentConfig(
      bankConfigured: (json['bankConfigured'] as bool?) ?? false,
      upiConfigured: (json['upiConfigured'] as bool?) ?? false,
    );
  }
}

class PharmacyDashboardRecentOrder {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final String customerPhone;
  final String orderStatus;
  final double payableAmount;
  final DateTime? purchaseDate;

  const PharmacyDashboardRecentOrder({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerPhone,
    required this.orderStatus,
    required this.payableAmount,
    this.purchaseDate,
  });

  factory PharmacyDashboardRecentOrder.fromJson(Map<String, dynamic> json) {
    return PharmacyDashboardRecentOrder(
      id: (json['id'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      customerName: (json['customerName'] ?? 'Walk-in Customer').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      orderStatus: (json['orderStatus'] ?? 'PLACED').toString(),
      payableAmount: (json['payableAmount'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.tryParse(json['purchaseDate'].toString())
          : null,
    );
  }
}

class PharmacyDashboardRecentPayment {
  final String id;
  final String customerName;
  final String customerCode;
  final double amount;
  final String paymentChannel;
  final String status;
  final DateTime? createdAt;

  const PharmacyDashboardRecentPayment({
    required this.id,
    required this.customerName,
    required this.customerCode,
    required this.amount,
    required this.paymentChannel,
    required this.status,
    this.createdAt,
  });

  factory PharmacyDashboardRecentPayment.fromJson(Map<String, dynamic> json) {
    return PharmacyDashboardRecentPayment(
      id: (json['id'] ?? '').toString(),
      customerName: (json['customerName'] ?? 'Customer').toString(),
      customerCode: (json['customerCode'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentChannel: (json['paymentChannel'] ?? 'BANK_TRANSFER').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class PharmacyDashboardModel {
  final PharmacyDashboardOrdersSummary orders;
  final PharmacyDashboardPaymentsSummary payments;
  final PharmacyDashboardPaymentConfig paymentConfiguration;
  final List<PharmacyDashboardRecentOrder> recentOrders;
  final List<PharmacyDashboardRecentPayment> recentPayments;

  const PharmacyDashboardModel({
    required this.orders,
    required this.payments,
    required this.paymentConfiguration,
    required this.recentOrders,
    required this.recentPayments,
  });

  factory PharmacyDashboardModel.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['recentOrders'] as List? ?? const [];
    final rawPayments = json['recentPayments'] as List? ?? const [];

    return PharmacyDashboardModel(
      orders: PharmacyDashboardOrdersSummary.fromJson(
        (json['orders'] as Map<String, dynamic>?) ?? {},
      ),
      payments: PharmacyDashboardPaymentsSummary.fromJson(
        (json['payments'] as Map<String, dynamic>?) ?? {},
      ),
      paymentConfiguration: PharmacyDashboardPaymentConfig.fromJson(
        (json['paymentConfiguration'] as Map<String, dynamic>?) ?? {},
      ),
      recentOrders: rawOrders
          .map((o) => PharmacyDashboardRecentOrder.fromJson(o as Map<String, dynamic>))
          .toList(),
      recentPayments: rawPayments
          .map((p) => PharmacyDashboardRecentPayment.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
