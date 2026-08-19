import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';

class PharmacyOrderHistoryPagination {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const PharmacyOrderHistoryPagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory PharmacyOrderHistoryPagination.fromJson(Map<String, dynamic> json) {
    return PharmacyOrderHistoryPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}

class PharmacyOrderHistorySummary {
  final int totalCompletedCount;
  final double completedOrderValue;
  final int totalCancelledCount;
  final int totalRejectedCount;

  const PharmacyOrderHistorySummary({
    required this.totalCompletedCount,
    required this.completedOrderValue,
    required this.totalCancelledCount,
    required this.totalRejectedCount,
  });

  factory PharmacyOrderHistorySummary.fromJson(Map<String, dynamic> json) {
    return PharmacyOrderHistorySummary(
      totalCompletedCount:
          (json['completedCount'] ?? json['totalCompletedCount'] as num?)?.toInt() ?? 0,
      completedOrderValue:
          (json['completedValue'] ?? json['completedOrderValue'] as num?)?.toDouble() ?? 0.0,
      totalCancelledCount:
          (json['cancelledCount'] ?? json['totalCancelledCount'] as num?)?.toInt() ?? 0,
      totalRejectedCount:
          (json['rejectedCount'] ?? json['totalRejectedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class PharmacyOrderHistoryResponse {
  final List<PharmacyOrderModel> orders;
  final PharmacyOrderHistoryPagination pagination;
  final PharmacyOrderHistorySummary summary;

  const PharmacyOrderHistoryResponse({
    required this.orders,
    required this.pagination,
    required this.summary,
  });

  factory PharmacyOrderHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawOrders = (json['items'] ?? json['orders']) as List? ?? const [];
    final summaryJson =
        (json['metrics'] ?? json['summary']) as Map<String, dynamic>? ?? {};
    return PharmacyOrderHistoryResponse(
      orders: rawOrders
          .map((o) => PharmacyOrderModel.fromJson(o as Map<String, dynamic>))
          .toList(),
      pagination: PharmacyOrderHistoryPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? {},
      ),
      summary: PharmacyOrderHistorySummary.fromJson(summaryJson),
    );
  }
}
