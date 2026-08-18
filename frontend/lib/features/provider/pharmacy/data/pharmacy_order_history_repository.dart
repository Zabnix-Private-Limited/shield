import 'package:shield/shared/services/api_service.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_history_model.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_order_model.dart';

class PharmacyOrderHistoryRepository {
  Future<PharmacyOrderHistoryResponse> fetchOrderHistory({
    String? status,
    String? source,
    String? fulfillment,
    String? search,
    String? from,
    String? to,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (source != null && source.isNotEmpty) queryParams['source'] = source;
    if (fulfillment != null && fulfillment.isNotEmpty) {
      queryParams['fulfillment'] = fulfillment;
    }
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (from != null && from.isNotEmpty) queryParams['from'] = from;
    if (to != null && to.isNotEmpty) queryParams['to'] = to;

    final response = await ApiService.dio.get(
      '/pharmacy/orders/history',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderHistoryResponse.fromJson(data);
  }

  Future<PharmacyOrderModel> fetchOrderHistoryDetail(String id) async {
    final response = await ApiService.dio.get('/pharmacy/orders/history/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderModel.fromJson(data);
  }
}
