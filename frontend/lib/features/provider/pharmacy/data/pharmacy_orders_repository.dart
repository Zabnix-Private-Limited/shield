import 'package:shield/shared/services/api_service.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';

class PharmacyOrdersRepository {
  Future<PharmacyOrdersSummary> fetchSummary() async {
    final response = await ApiService.dio.get('/pharmacy/orders/summary');
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrdersSummary.fromJson(data);
  }

  Future<List<PharmacyOrderModel>> fetchOrders({
    String status = 'ALL',
    String? query,
    int page = 1,
    int pageSize = 25,
  }) async {
    final queryParameters = <String, dynamic>{
      'status': status,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (query != null && query.trim().isNotEmpty) {
      queryParameters['query'] = query.trim();
    }

    final response = await ApiService.dio.get(
      '/pharmacy/orders',
      queryParameters: queryParameters,
    );

    final rawData = response.data['data'];
    List itemsList;
    if (rawData is Map<String, dynamic> && rawData['items'] != null) {
      itemsList = rawData['items'] as List;
    } else if (rawData is List) {
      itemsList = rawData;
    } else {
      itemsList = const [];
    }

    return itemsList
        .map((item) => PharmacyOrderModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PharmacyOrderModel> fetchOrderDetail(String orderId) async {
    final response = await ApiService.dio.get('/pharmacy/orders/$orderId');
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderModel.fromJson(data);
  }

  Future<PharmacyOrderModel> updateOrderStatus({
    required String orderId,
    required String status,
    String? cancellationReason,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
    };
    if (cancellationReason != null && cancellationReason.trim().isNotEmpty) {
      payload['cancellationReason'] = cancellationReason.trim();
    }

    final response = await ApiService.dio.patch(
      '/pharmacy/orders/$orderId/status',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderModel.fromJson(data);
  }
}
