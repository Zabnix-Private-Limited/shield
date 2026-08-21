import 'package:dio/dio.dart';
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
        .map(
          (item) => PharmacyOrderModel.fromJson(item as Map<String, dynamic>),
        )
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
    final payload = <String, dynamic>{'status': status};
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

  Future<PharmacyOrderModel> updateOrderItemFulfillment({
    required String orderId,
    required String itemId,
    double? fulfillQuantity,
    String? stockStatus,
    String? decisionStatus,
    String? substituteName,
    double? substituteUnitPrice,
    String? decisionReason,
  }) async {
    final response = await ApiService.dio.patch(
      '/pharmacy/orders/$orderId/items/$itemId',
      data: {
        if (fulfillQuantity != null) 'fulfillQuantity': fulfillQuantity,
        if (stockStatus != null) 'stockStatus': stockStatus,
        if (decisionStatus != null) 'decisionStatus': decisionStatus,
        if (substituteName != null) 'substituteName': substituteName,
        if (substituteUnitPrice != null)
          'substituteUnitPrice': substituteUnitPrice,
        if (decisionReason != null) 'decisionReason': decisionReason,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderModel.fromJson(data);
  }

  Future<PharmacyOrderModel> toggleChronicOrder({
    required String orderId,
    required bool isChronic,
    int? repeatIntervalDays,
  }) async {
    final response = await ApiService.dio.patch(
      '/pharmacy/orders/$orderId/chronic',
      data: {
        'isChronic': isChronic,
        if (repeatIntervalDays != null)
          'repeatIntervalDays': repeatIntervalDays,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderModel.fromJson(data);
  }

  Future<PharmacyOrderModel> savePharmacistNotes({
    required String orderId,
    required String notes,
  }) async {
    final response = await ApiService.dio.post(
      '/pharmacy/orders/$orderId/notes',
      data: {'notes': notes},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderModel.fromJson(data);
  }

  Future<PharmacyOrderModel> requestCustomerConfirmation({
    required String orderId,
    String? reason,
  }) async {
    final response = await ApiService.dio.post(
      '/pharmacy/orders/$orderId/request-customer-confirmation',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderModel.fromJson(data);
  }

  Future<PharmacyOrderModel> uploadOrderInvoiceFile({
    required String orderId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await ApiService.dio.post(
      '/pharmacy/orders/$orderId/invoice/upload',
      data: formData,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderModel.fromJson(data);
  }

  Future<PharmacyOrderModel> removeOrderInvoice({
    required String orderId,
  }) async {
    final response = await ApiService.dio.delete(
      '/pharmacy/orders/$orderId/invoice',
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderModel.fromJson(data);
  }

  Future<PharmacyOrderModel> sendOrderInvoice({required String orderId}) async {
    final response = await ApiService.dio.post(
      '/pharmacy/orders/$orderId/send-invoice',
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyOrderModel.fromJson(data);
  }

  Future<Map<String, dynamic>> fetchPharmacyProfile() async {
    final response = await ApiService.dio.get('/pharmacy/profile');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePharmacyProfile(
    Map<String, dynamic> payload,
  ) async {
    final response = await ApiService.dio.patch(
      '/pharmacy/profile',
      data: payload,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchPharmacySettings() async {
    final response = await ApiService.dio.get('/pharmacy/settings');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePharmacySettings(
    Map<String, dynamic> payload,
  ) async {
    final response = await ApiService.dio.patch(
      '/pharmacy/settings',
      data: payload,
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
