import 'package:dio/dio.dart';
import 'package:shield/shared/services/api_service.dart';
import 'package:shield/features/provider/pharmacy/domain/models/pharmacy_payment_method_model.dart';

class PharmacyPaymentDetailsRepository {
  Future<PharmacyPaymentDetailsResponse> fetchPaymentDetails() async {
    final response = await ApiService.dio.get('/pharmacy/payment-details');
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentDetailsResponse.fromJson(data);
  }

  Future<PharmacyPaymentMethodModel> createBankAccount({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    String? branchName,
    String? displayLabel,
    bool isPrimary = false,
  }) async {
    final payload = <String, dynamic>{
      'accountHolderName': accountHolderName.trim(),
      'bankName': bankName.trim(),
      'accountNumber': accountNumber.trim(),
      'ifscCode': ifscCode.trim().toUpperCase(),
      'isPrimary': isPrimary,
    };
    if (branchName != null && branchName.trim().isNotEmpty) {
      payload['branchName'] = branchName.trim();
    }
    if (displayLabel != null && displayLabel.trim().isNotEmpty) {
      payload['displayLabel'] = displayLabel.trim();
    }

    final response = await ApiService.dio.post(
      '/pharmacy/payment-details/bank-accounts',
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentMethodModel.fromJson(data);
  }

  Future<PharmacyPaymentMethodModel> updateBankAccount({
    required String id,
    String? accountHolderName,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? branchName,
    String? displayLabel,
    bool? isPrimary,
  }) async {
    final payload = <String, dynamic>{};
    if (accountHolderName != null) payload['accountHolderName'] = accountHolderName.trim();
    if (bankName != null) payload['bankName'] = bankName.trim();
    if (accountNumber != null) payload['accountNumber'] = accountNumber.trim();
    if (ifscCode != null) payload['ifscCode'] = ifscCode.trim().toUpperCase();
    if (branchName != null) payload['branchName'] = branchName.trim();
    if (displayLabel != null) payload['displayLabel'] = displayLabel.trim();
    if (isPrimary != null) payload['isPrimary'] = isPrimary;

    final response = await ApiService.dio.patch(
      '/pharmacy/payment-details/bank-accounts/$id',
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentMethodModel.fromJson(data);
  }

  Future<PharmacyPaymentMethodModel> createUpi({
    required String upiId,
    String? displayLabel,
    bool isPrimary = false,
  }) async {
    final payload = <String, dynamic>{
      'upiId': upiId.trim().toLowerCase(),
      'isPrimary': isPrimary,
    };
    if (displayLabel != null && displayLabel.trim().isNotEmpty) {
      payload['displayLabel'] = displayLabel.trim();
    }

    final response = await ApiService.dio.post(
      '/pharmacy/payment-details/upi',
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentMethodModel.fromJson(data);
  }

  Future<PharmacyPaymentMethodModel> updateUpi({
    required String id,
    String? upiId,
    String? displayLabel,
    bool? isPrimary,
  }) async {
    final payload = <String, dynamic>{};
    if (upiId != null) payload['upiId'] = upiId.trim().toLowerCase();
    if (displayLabel != null) payload['displayLabel'] = displayLabel.trim();
    if (isPrimary != null) payload['isPrimary'] = isPrimary;

    final response = await ApiService.dio.patch(
      '/pharmacy/payment-details/upi/$id',
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentMethodModel.fromJson(data);
  }

  Future<PharmacyPaymentMethodModel> uploadUpiQr({
    required String id,
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
    });

    final response = await ApiService.dio.post(
      '/pharmacy/payment-details/upi/$id/qr',
      data: formData,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentMethodModel.fromJson(data);
  }

  Future<PharmacyPaymentMethodModel> removeUpiQr(String id) async {
    final response = await ApiService.dio.delete(
      '/pharmacy/payment-details/upi/$id/qr',
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return PharmacyPaymentMethodModel.fromJson(data);
  }

  Future<void> setPrimary(String id) async {
    await ApiService.dio.patch('/pharmacy/payment-details/$id/primary');
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await ApiService.dio.patch(
      '/pharmacy/payment-details/$id/toggle-active',
      data: {'isActive': isActive},
    );
  }
}
