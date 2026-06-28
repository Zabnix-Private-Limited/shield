import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/models/shield_role.dart';
import '../../features/portal/presentation/portal_role_data.dart';
import '../config/app_config.dart';
import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/document.dart';
import '../models/membership.dart';
import '../models/notification.dart';
import '../models/prescription_analysis.dart';
import '../models/wallet.dart';

class ApiService {
  static const Duration _mockDelay = Duration(milliseconds: 180);
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  static String _resolveBaseUrl() {
    if (AppConfig.apiBaseUrl.trim().isNotEmpty) {
      return AppConfig.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    final base = Uri.base;
    final host = base.host.isEmpty ? 'localhost' : base.host;
    final isLocalHost = host == 'localhost' || host == '127.0.0.1';
    final scheme = isLocalHost ? 'http' : (base.scheme.isEmpty ? 'http' : base.scheme);
    final resolvedHost = isLocalHost ? '127.0.0.1' : host;
    return '$scheme://$resolvedHost:3000';
  }

  static Map<String, dynamic> _readEnvelope(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    throw const FormatException('Unexpected API response envelope');
  }

  static List<dynamic> _readEnvelopeList(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        return data;
      }
    }
    throw const FormatException('Unexpected API list response envelope');
  }

  static Customer _mockCustomer(String customerId) {
    return dummyCustomers.firstWhere(
      (customer) => customer.id == customerId,
      orElse: () => dummyCustomers.first,
    );
  }

  static Future<Map<String, dynamic>> _getCustomerPayload(
    String customerId,
  ) async {
    final response = await _dio.get('/customers/$customerId');
    return _readEnvelope(response);
  }

  static Future<List<WalletTransaction>> _getWalletTransactionsFromBackend(
    String walletId,
  ) async {
    final response = await _dio.get('/wallets/$walletId/transactions');
    return _readEnvelopeList(response)
        .map((item) => WalletTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<PortalSectionData> getRoleSectionData(
    SHIELDRole role,
    String section,
  ) async {
    await Future<void>.delayed(_mockDelay);
    return portalDataForRole(role).sectionFor(section);
  }

  static Future<List<Appointment>> getAppointments(SHIELDRole role) async {
    if (role == SHIELDRole.customer) {
      try {
        final response = await _dio.get(
          '/appointments',
          queryParameters: {'customer_id': '1'},
        );
        return _readEnvelopeList(response)
            .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
      } catch (_) {}
    }
    await Future<void>.delayed(_mockDelay);
    if (role == SHIELDRole.customer) {
      return dummyAppointments
          .where((appointment) => appointment.customerId == '1')
          .toList()
        ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    }
    return dummyAppointments;
  }

  static Future<List<Document>> getDocuments(SHIELDRole role) async {
    if (role == SHIELDRole.customer) {
      try {
        final response = await _dio.get(
          '/documents',
          queryParameters: {'customer_id': '1'},
        );
        return _readEnvelopeList(response)
            .map((item) => Document.fromJson(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      } catch (_) {}
    }
    await Future<void>.delayed(_mockDelay);
    if (role == SHIELDRole.customer) {
      return dummyDocuments
          .where((document) => document.customerId == '1')
          .toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    }
    return dummyDocuments;
  }

  static Future<List<Document>> getCustomerDocumentsStrict(String customerId) async {
    final response = await _dio.get(
      '/documents',
      queryParameters: {'customer_id': customerId},
      options: Options(receiveTimeout: const Duration(minutes: 1)),
    );
    return _readEnvelopeList(response)
        .map((item) => Document.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  static Future<List<NotificationModel>> getNotifications(
    SHIELDRole role,
  ) async {
    if (role == SHIELDRole.customer) {
      try {
        final response = await _dio.get(
          '/notifications',
          queryParameters: {'customer_id': '1'},
        );
        return _readEnvelopeList(response)
            .map(
              (item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (_) {}
    }
    await Future<void>.delayed(_mockDelay);
    if (role == SHIELDRole.customer) {
      return dummyNotifications
          .where((notification) => notification.customerId == '1')
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return dummyNotifications;
  }

  static Future<Customer> getCustomerProfile(String customerId) async {
    try {
      final payload = await _getCustomerPayload(customerId);
      return Customer.fromJson(payload);
    } catch (_) {
      await Future<void>.delayed(_mockDelay);
      return _mockCustomer(customerId);
    }
  }

  static Future<Customer> updateCustomerProfile(
    String customerId,
    Customer customer,
  ) async {
    final response = await _dio.put(
      '/customers/$customerId',
      data: {
        'first_name': customer.firstName,
        'last_name': customer.lastName,
        'dob': customer.dob?.toIso8601String(),
        'gender': customer.gender,
        'email': customer.email,
        'address_line1': customer.addressLine1,
        'address_line2': customer.addressLine2,
        'city': customer.city,
        'district': customer.district,
        'state': customer.state,
        'pincode': customer.pincode,
        'blood_group': customer.bloodGroup,
      },
    );
    return Customer.fromJson(_readEnvelope(response));
  }

  static Future<Map<String, dynamic>> getWalletProfile(
    String customerId,
  ) async {
    try {
      final response = await _dio.get('/wallets/$customerId');
      final wallet = _readEnvelope(response);
      final walletId = wallet['walletId'].toString();
      final transactions = await _getWalletTransactionsFromBackend(walletId);
      final pointsBalance = transactions
          .where((txn) => txn.subLedgerType.toUpperCase() == 'POINTS')
          .fold<double>(
            0,
            (total, txn) =>
                total +
                (txn.transactionType.toUpperCase() == 'CREDIT'
                    ? txn.amount
                    : -txn.amount),
          );

      return {
        'walletId': walletId,
        'customerId': wallet['customerId'].toString(),
        'balance': double.tryParse(wallet['balance'].toString()) ?? 0,
        'cashBalance': double.tryParse(wallet['balance'].toString()) ?? 0,
        'pointsBalance': pointsBalance,
        'creditAvailable':
            double.tryParse((wallet['credit_available'] ?? 0).toString()) ?? 0,
        'status': (wallet['status'] ?? 'ACTIVE').toString(),
      };
    } catch (_) {
      await Future<void>.delayed(_mockDelay);
      final transactions = dummyTransactions
          .where((transaction) => transaction.walletId == dummyWallet.id)
          .toList();

      double cashBalance = 0;
      double pointsBalance = 0;
      for (final transaction in transactions) {
        final delta = transaction.transactionType == 'CREDIT'
            ? transaction.amount
            : -transaction.amount;
        if (transaction.subLedgerType == 'POINTS') {
          pointsBalance += delta;
        } else {
          cashBalance += delta;
        }
      }

      return {
        'walletId': dummyWallet.id,
        'customerId': customerId,
        'cashBalance': cashBalance,
        'pointsBalance': pointsBalance,
        'balance': cashBalance,
        'status': dummyWallet.status,
      };
    }
  }

  static Future<List<WalletTransaction>> getWalletTransactions(
    String walletId,
  ) async {
    try {
      return await _getWalletTransactionsFromBackend(walletId);
    } catch (_) {
      await Future<void>.delayed(_mockDelay);
      return dummyTransactions
          .where((transaction) => transaction.walletId == walletId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  static Future<Membership> getCustomerMembership(String customerId) async {
    try {
      final customerPayload = await _getCustomerPayload(customerId);
      final customer = Customer.fromJson(customerPayload);
      final walletData = customerPayload['wallet'] as Map<String, dynamic>?;
      final transactions = walletData == null
          ? <WalletTransaction>[]
          : await _getWalletTransactionsFromBackend(
              walletData['id'].toString(),
            );

      return Membership.fromApi(
        customer: customer,
        customerPayload: customerPayload,
        transactions: transactions,
      );
    } catch (_) {
      await Future<void>.delayed(_mockDelay);
      return dummyMembership;
    }
  }

  static Future<Appointment> createCustomerAppointment({
    required String providerId,
    required String appointmentType,
    required DateTime appointmentDate,
    String? remarks,
  }) async {
    final response = await _dio.post(
      '/appointments',
      data: {
        'customer_id': '1',
        'provider_id': providerId,
        'appointment_type': appointmentType,
        'appointment_date': appointmentDate.toIso8601String(),
        'remarks': remarks,
      },
    );
    return Appointment.fromJson(_readEnvelope(response));
  }

  static Future<Appointment> cancelCustomerAppointment(
    String appointmentId,
  ) async {
    final response = await _dio.post('/appointments/$appointmentId/cancel');
    return Appointment.fromJson(_readEnvelope(response));
  }

  static Future<Document> uploadCustomerDocument({
    required String fileName,
    required String documentType,
    required Uint8List fileBytes,
    String mimeType = 'application/pdf',
    int fileSize = 1024,
  }) async {
    final formData = FormData.fromMap({
      'customer_id': '1',
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'document_type': documentType,
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/documents/upload',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    return Document.fromJson(_readEnvelope(response));
  }

  static Future<PrescriptionAnalysis> getPrescriptionAnalysis(
    String documentId,
  ) async {
    final response = await _dio.get(
      '/document-intelligence/prescription-review/$documentId',
      options: Options(receiveTimeout: const Duration(minutes: 1)),
    );
    return PrescriptionAnalysis.fromJson(_readEnvelope(response));
  }

  static Future<PrescriptionAnalysis> approvePrescriptionAnalysis(
    String documentId, {
    String staffId = '1',
    String? providerId,
  }) async {
    final response = await _dio.post(
      '/document-intelligence/prescription-review/$documentId/approve',
      data: {
        'staff_id': staffId,
        if (providerId != null) 'provider_id': providerId,
      },
    );
    return PrescriptionAnalysis.fromJson(_readEnvelope(response));
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await _dio.post('/notifications/$notificationId/read');
  }

  static Future<void> registerPushToken({
    required String token,
    required String platform,
    String? deviceLabel,
    String customerId = '1',
  }) async {
    await _dio.post(
      '/notifications/device-token',
      data: {
        'customer_id': customerId,
        'token': token,
        'platform': platform,
        if (deviceLabel != null && deviceLabel.trim().isNotEmpty)
          'device_label': deviceLabel.trim(),
      },
    );
  }

  static Future<void> deactivatePushToken(String token) async {
    await _dio.post(
      '/notifications/device-token/deactivate',
      data: {'token': token},
    );
  }

  static String resolvePushPlatform() {
    if (kIsWeb) {
      return 'WEB';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.windows:
        return 'WINDOWS';
      case TargetPlatform.macOS:
        return 'MACOS';
      case TargetPlatform.linux:
        return 'LINUX';
      case TargetPlatform.fuchsia:
        return 'FUCHSIA';
    }
  }
}
