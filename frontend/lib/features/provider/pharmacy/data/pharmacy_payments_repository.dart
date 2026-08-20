import 'package:shield/shared/services/api_service.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_dashboard_model.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_request_model.dart';

class PharmacyPaymentsRepository {
  Future<PharmacyDashboardModel> fetchPharmacyDashboard() async {
    final response = await ApiService.dio.get('/pharmacy/dashboard');
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyDashboardModel.fromJson(data);
  }

  Future<List<PharmacyPaymentRequestModel>> fetchPayments({
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await ApiService.dio.get(
      '/pharmacy/payments',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final rawPayments = data['payments'] as List? ?? const [];

    return rawPayments
        .map((p) => PharmacyPaymentRequestModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<PharmacyPaymentRequestModel> fetchPaymentDetail(String id) async {
    final response = await ApiService.dio.get('/pharmacy/payments/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentRequestModel.fromJson(data);
  }

  Future<PharmacyPaymentRequestModel> approvePayment(String id) async {
    final response = await ApiService.dio.post('/pharmacy/payments/$id/approve');
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentRequestModel.fromJson(data);
  }

  Future<PharmacyPaymentRequestModel> rejectPayment(
    String id,
    String rejectionReason,
  ) async {
    final response = await ApiService.dio.post(
      '/pharmacy/payments/$id/reject',
      data: {'rejectionReason': rejectionReason.trim()},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentRequestModel.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final response = await ApiService.dio.get(
      '/pharmacy/customers/search',
      queryParameters: {'q': query.trim()},
    );
    final data = response.data['data'] as List? ?? const [];
    return data.map((c) => Map<String, dynamic>.from(c as Map)).toList();
  }

  Future<PharmacyPaymentRequestModel> submitManualPayment({
    required String customerId,
    required double amount,
    required String paymentChannel,
    String? paymentMethodId,
    String? referenceNumber,
    String? customerNotes,
    bool autoApprove = false,
  }) async {
    final payload = <String, dynamic>{
      'customerId': customerId.trim(),
      'amount': amount,
      'paymentChannel': paymentChannel,
      'autoApprove': autoApprove,
    };
    if (paymentMethodId != null && paymentMethodId.isNotEmpty) {
      payload['paymentMethodId'] = paymentMethodId;
    }
    if (referenceNumber != null && referenceNumber.isNotEmpty) {
      payload['referenceNumber'] = referenceNumber;
    }
    if (customerNotes != null && customerNotes.isNotEmpty) {
      payload['customerNotes'] = customerNotes;
    }

    final response = await ApiService.dio.post(
      '/pharmacy/payments/submit',
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentRequestModel.fromJson(data);
  }
}
