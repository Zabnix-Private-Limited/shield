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
  static String? _accessToken;
  static String? _activeCustomerId;
  static final Map<String, Map<String, dynamic>>
  _providerPlatformWorkspaceCache = <String, Map<String, dynamic>>{};
  static Future<String?> Function()? _onRefreshToken;
  static Future<void> Function()? _onSessionExpired;
  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: _resolveBaseUrl(),
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 8),
            headers: const {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final accessToken = _accessToken?.trim();
              if (accessToken != null && accessToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $accessToken';
              } else {
                options.headers.remove('Authorization');
              }
              handler.next(options);
            },
            onError: (error, handler) async {
              final response = error.response;
              final options = error.requestOptions;
              final isUnauthorized = response?.statusCode == 401;
              final isAuthEndpoint = options.path.startsWith('/auth/');
              final alreadyRetried = options.extra['retried'] == true;

              if (isUnauthorized &&
                  !isAuthEndpoint &&
                  !alreadyRetried &&
                  _onRefreshToken != null) {
                final refreshedToken = await _onRefreshToken!.call();
                if (refreshedToken != null &&
                    refreshedToken.trim().isNotEmpty) {
                  options.extra['retried'] = true;
                  options.headers['Authorization'] = 'Bearer $refreshedToken';
                  final retryResponse = await _dio.fetch<dynamic>(options);
                  return handler.resolve(retryResponse);
                }
                if (_onSessionExpired != null) {
                  await _onSessionExpired!.call();
                }
              }

              handler.next(error);
            },
          ),
        );

  static void configureAuthHandlers({
    Future<String?> Function()? onRefreshToken,
    Future<void> Function()? onSessionExpired,
  }) {
    _onRefreshToken = onRefreshToken;
    _onSessionExpired = onSessionExpired;
  }

  static void setAccessToken(String accessToken) {
    _accessToken = accessToken.trim();
    _providerPlatformWorkspaceCache.clear();
  }

  static void clearAccessToken() {
    _accessToken = null;
    _providerPlatformWorkspaceCache.clear();
  }

  static void setActiveCustomerId(String? customerId) {
    _activeCustomerId = customerId?.trim();
  }

  static String requireAuthenticatedCustomerId([String? customerId]) {
    return _requireCustomerId(customerId);
  }

  static String _requireCustomerId([String? customerId]) {
    final activeCustomerId = _activeCustomerId?.trim();
    if (activeCustomerId != null && activeCustomerId.isNotEmpty) {
      return activeCustomerId;
    }
    final normalized = customerId?.trim() ?? '';
    if (normalized.isNotEmpty) {
      return normalized;
    }
    throw StateError('Authenticated customer session is required.');
  }

  static String? _resolveOptionalCustomerId([String? customerId]) {
    final activeCustomerId = _activeCustomerId?.trim();
    if (activeCustomerId != null && activeCustomerId.isNotEmpty) {
      return activeCustomerId;
    }
    final normalized = customerId?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static String _resolveBaseUrl() {
    if (AppConfig.apiBaseUrl.trim().isNotEmpty) {
      if (!kIsWeb &&
          kReleaseMode &&
          (AppConfig.apiBaseUrl.contains('localhost') ||
              AppConfig.apiBaseUrl.contains('127.0.0.1'))) {
        return 'https://shield-backend.vercel.app';
      }
      return AppConfig.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }

    if (!kIsWeb) {
      if (kReleaseMode) {
        return 'https://shield-backend.vercel.app';
      } else {
        return 'http://10.0.2.2:3000'; // Android emulator host loopback
      }
    }

    final base = Uri.base;
    final host = base.host.isEmpty ? 'localhost' : base.host;
    final isLocalHost = host == 'localhost' || host == '127.0.0.1';
    if (!isLocalHost && host.contains('vercel.app')) {
      return 'https://shield-backend.vercel.app';
    }
    final scheme = isLocalHost
        ? 'http'
        : (base.scheme.isEmpty ? 'http' : base.scheme);
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

  static Future<Map<String, dynamic>> _getCustomerPayload(
    String customerId,
  ) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final response = await _dio.get('/customers/$resolvedCustomerId');
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
    final customerId = _resolveOptionalCustomerId();
    final response = await _dio.get(
      '/dashboard/role/${role.routeKey}/$section',
      queryParameters: customerId == null
          ? null
          : <String, dynamic>{'customer_id': customerId},
    );
    return PortalSectionData.fromJson(_readEnvelope(response));
  }

  static Future<List<Appointment>> getAppointments(SHIELDRole role) async {
    if (role != SHIELDRole.customer) {
      throw UnsupportedError(
        'Live appointments are only wired for authenticated customer flows here.',
      );
    }
    final customerId = _requireCustomerId();
    final response = await _dio.get(
      '/appointments',
      queryParameters: {'customer_id': customerId},
    );
    return _readEnvelopeList(response)
        .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  static Future<List<Appointment>> getAppointmentsByCustomerId(
    String customerId,
  ) async {
    final response = await _dio.get(
      '/appointments',
      queryParameters: {'customer_id': customerId},
    );
    return _readEnvelopeList(response)
        .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  static Future<Map<String, dynamic>> getAppointmentConsultationWorkspace(
    String appointmentId,
  ) async {
    final response = await _dio.get(
      '/appointments/$appointmentId/consultation-workspace',
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> startAppointmentConsultation(
    String appointmentId,
  ) async {
    final response = await _dio.post(
      '/appointments/$appointmentId/start-consultation',
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> saveAppointmentConsultation(
    String appointmentId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post(
      '/appointments/$appointmentId/consultation',
      data: payload,
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> completeAppointmentConsultation(
    String appointmentId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post(
      '/appointments/$appointmentId/complete-consultation',
      data: payload,
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> saveAppointmentVisitBilling(
    String appointmentId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post(
      '/appointments/$appointmentId/visit-billing',
      data: payload,
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> generateAppointmentVisitInvoice(
    String appointmentId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post(
      '/appointments/$appointmentId/generate-invoice',
      data: payload,
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> recordAppointmentVisitPayment(
    String appointmentId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post(
      '/appointments/$appointmentId/record-payment',
      data: payload,
    );
    return _readEnvelope(response);
  }

  static Future<List<Document>> getDocuments(SHIELDRole role) async {
    if (role != SHIELDRole.customer) {
      throw UnsupportedError(
        'Live documents are only wired for authenticated customer flows here.',
      );
    }
    final customerId = _requireCustomerId();
    final response = await _dio.get(
      '/documents',
      queryParameters: {'customer_id': customerId},
      options: Options(receiveTimeout: const Duration(minutes: 1)),
    );
    return _readEnvelopeList(
        response,
      ).map((item) => Document.fromJson(item as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  static Future<List<Document>> getCustomerDocumentsStrict(
    String customerId,
  ) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final response = await _dio.get(
      '/documents',
      queryParameters: {'customer_id': resolvedCustomerId},
      options: Options(receiveTimeout: const Duration(minutes: 1)),
    );
    return _readEnvelopeList(
        response,
      ).map((item) => Document.fromJson(item as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  static Future<List<NotificationModel>> getCustomerNotificationsStrict(
    String customerId,
  ) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final response = await _dio.get(
      '/notifications',
      queryParameters: {'customer_id': resolvedCustomerId},
    );
    return _readEnvelopeList(response)
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<List<Map<String, dynamic>>> getCustomerPurchases(
    String customerId,
  ) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final response = await _dio.get(
      '/pharmacy/purchases',
      queryParameters: {'customer_id': resolvedCustomerId},
    );
    final purchases = _readEnvelopeList(
      response,
    ).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    purchases.sort((left, right) {
      final leftDate =
          DateTime.tryParse(
            left['purchaseDate']?.toString() ??
                left['purchase_date']?.toString() ??
                '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          DateTime.tryParse(
            right['purchaseDate']?.toString() ??
                right['purchase_date']?.toString() ??
                '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return rightDate.compareTo(leftDate);
    });
    return purchases;
  }

  static Future<List<NotificationModel>> getNotifications(
    SHIELDRole role,
  ) async {
    if (role != SHIELDRole.customer) {
      throw UnsupportedError(
        'Live notifications are only wired for authenticated customer flows here.',
      );
    }
    final customerId = _requireCustomerId();
    final response = await _dio.get(
      '/notifications',
      queryParameters: {'customer_id': customerId},
    );
    return _readEnvelopeList(response)
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<Customer> getCustomerProfile(String customerId) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final payload = await _getCustomerPayload(resolvedCustomerId);
    return Customer.fromJson(payload);
  }

  static Future<Customer> updateCustomerProfile(
    String customerId,
    Customer customer,
  ) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final response = await _dio.put(
      '/customers/$resolvedCustomerId',
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
    final resolvedCustomerId = _requireCustomerId(customerId);
    final response = await _dio.get('/wallets/$resolvedCustomerId');
    final wallet = _readEnvelope(response);
    final walletId = wallet['walletId'].toString();
    final transactions = await _getWalletTransactionsFromBackend(walletId);
    final cashWallet = wallet['cashWallet'] is Map<String, dynamic>
        ? wallet['cashWallet'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rewardPoints = wallet['rewardPoints'] is Map<String, dynamic>
        ? wallet['rewardPoints'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final cashBalance =
        double.tryParse((cashWallet['available'] ?? 0).toString()) ?? 0;
    final pointsBalance =
        double.tryParse((rewardPoints['available'] ?? 0).toString()) ?? 0;

    return {
      'walletId': walletId,
      'customerId': wallet['customerId'].toString(),
      'balance': cashBalance,
      'cashBalance': cashBalance,
      'pointsBalance': pointsBalance,
      'creditAvailable':
          double.tryParse((wallet['creditAvailable'] ?? 0).toString()) ?? 0,
      'status': (wallet['status'] ?? 'ACTIVE').toString(),
      'transactionsLoaded': transactions.isNotEmpty,
    };
  }

  static Future<List<WalletTransaction>> getWalletTransactions(
    String walletId,
  ) async {
    return _getWalletTransactionsFromBackend(walletId);
  }

  static Future<Map<String, dynamic>> getCustomerWalletBundle(
    String customerId,
  ) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final response = await _dio.get(
      '/customer/wallet',
      queryParameters: {'customer_id': resolvedCustomerId},
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> getCustomerMembershipBundle(
    String customerId,
  ) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final response = await _dio.get(
      '/customer/membership',
      queryParameters: {'customer_id': resolvedCustomerId},
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> getProviderPatientWorkspace(
    String customerId,
  ) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final response = await _dio.get(
      '/service-providers/workspace/patients/$resolvedCustomerId',
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> getAuthenticatedProfile() async {
    final response = await _dio.get('/auth/me');
    return _readEnvelope(response);
  }

  static Future<List<Map<String, dynamic>>> getAuthenticatedSessions() async {
    final response = await _dio.get('/auth/sessions');
    return _readEnvelopeList(
      response,
    ).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<List<Map<String, dynamic>>> getLoginHistory({
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/auth/login-history',
      queryParameters: {'limit': limit},
    );
    return _readEnvelopeList(
      response,
    ).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<void> revokeSession(String sessionId) async {
    await _dio.post('/auth/sessions/$sessionId/revoke');
  }

  static Future<Map<String, dynamic>> customerLogin({
    required String firebaseIdToken,
    String? deviceId,
    String? deviceLabel,
    String? platform,
  }) async {
    final response = await _dio.post(
      '/auth/customer/login',
      data: {
        'firebase_id_token': firebaseIdToken,
        if (deviceId != null && deviceId.trim().isNotEmpty)
          'device_id': deviceId.trim(),
        if (deviceLabel != null && deviceLabel.trim().isNotEmpty)
          'device_label': deviceLabel.trim(),
        if (platform != null && platform.trim().isNotEmpty)
          'platform': platform.trim(),
      },
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> customerRegister({
    required String firebaseIdToken,
    required String name,
    required DateTime dob,
    required String gender,
    String? deviceId,
    String? deviceLabel,
    String? platform,
  }) async {
    final response = await _dio.post(
      '/auth/customer/register',
      data: {
        'firebase_id_token': firebaseIdToken,
        'name': name.trim(),
        'dob': dob.toIso8601String(),
        'gender': gender,
        if (deviceId != null && deviceId.trim().isNotEmpty)
          'device_id': deviceId.trim(),
        if (deviceLabel != null && deviceLabel.trim().isNotEmpty)
          'device_label': deviceLabel.trim(),
        if (platform != null && platform.trim().isNotEmpty)
          'platform': platform.trim(),
      },
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> internalLogin({
    required String firebaseIdToken,
    String? deviceId,
    String? deviceLabel,
    String? platform,
  }) async {
    final response = await _dio.post(
      '/auth/internal/login',
      data: {
        'firebase_id_token': firebaseIdToken,
        if (deviceId != null && deviceId.trim().isNotEmpty)
          'device_id': deviceId.trim(),
        if (deviceLabel != null && deviceLabel.trim().isNotEmpty)
          'device_label': deviceLabel.trim(),
        if (platform != null && platform.trim().isNotEmpty)
          'platform': platform.trim(),
      },
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>> refreshSession(
    String refreshToken,
    String? deviceId,
    String? deviceLabel,
    String? platform,
  ) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {
        'refresh_token': refreshToken,
        if (deviceId != null && deviceId.trim().isNotEmpty)
          'device_id': deviceId.trim(),
        if (deviceLabel != null && deviceLabel.trim().isNotEmpty)
          'device_label': deviceLabel.trim(),
        if (platform != null && platform.trim().isNotEmpty)
          'platform': platform.trim(),
      },
    );
    return _readEnvelope(response);
  }

  static Future<void> logout(
    String refreshToken, {
    String? deviceId,
    String? deviceLabel,
    String? platform,
  }) async {
    await _dio.post(
      '/auth/logout',
      data: {
        'refresh_token': refreshToken,
        if (deviceId != null && deviceId.trim().isNotEmpty)
          'device_id': deviceId.trim(),
        if (deviceLabel != null && deviceLabel.trim().isNotEmpty)
          'device_label': deviceLabel.trim(),
        if (platform != null && platform.trim().isNotEmpty)
          'platform': platform.trim(),
      },
    );
  }

  static Future<Map<String, dynamic>> getCustomerDashboardBundle(
    String customerId,
  ) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final response = await _dio.get(
      '/customer/dashboard',
      queryParameters: {'customer_id': resolvedCustomerId},
    );
    return _readEnvelope(response);
  }

  static Future<Membership> getCustomerMembership(String customerId) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    final customerPayload = await _getCustomerPayload(resolvedCustomerId);
    final customer = Customer.fromJson(customerPayload);
    final walletData = customerPayload['wallet'] as Map<String, dynamic>?;
    final transactions = walletData == null
        ? <WalletTransaction>[]
        : await _getWalletTransactionsFromBackend(walletData['id'].toString());

    return Membership.fromApi(
      customer: customer,
      customerPayload: customerPayload,
      transactions: transactions,
    );
  }

  static Future<Appointment> createCustomerAppointment({
    required String providerId,
    required String appointmentType,
    required DateTime appointmentDate,
    String? remarks,
  }) async {
    final customerId = _requireCustomerId();
    final response = await _dio.post(
      '/appointments',
      data: {
        'customer_id': customerId,
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
    final customerId = _requireCustomerId();
    final formData = FormData.fromMap({
      'customer_id': customerId,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'document_type': documentType,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
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
    String? deviceId,
    String? customerId,
  }) async {
    final resolvedCustomerId = _requireCustomerId(customerId);
    await _dio.post(
      '/notifications/device-token',
      data: {
        'customer_id': resolvedCustomerId,
        'token': token,
        'platform': platform,
        if (deviceId != null && deviceId.trim().isNotEmpty)
          'device_id': deviceId.trim(),
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

  static Future<void> submitSupportContact({
    required String name,
    required String phone,
    required String message,
    String? email,
    String? subject,
    String? turnstileToken,
    String? customerId,
  }) async {
    final resolvedCustomerId = _resolveOptionalCustomerId(customerId);
    await _dio.post(
      '/support/contact',
      data: {
        if (resolvedCustomerId != null) 'customer_id': resolvedCustomerId,
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email?.trim(),
        'subject': subject?.trim(),
        'message': message.trim(),
        'channel': kIsWeb ? 'WEB' : resolvePushPlatform(),
        if (turnstileToken != null && turnstileToken.trim().isNotEmpty)
          'turnstile_token': turnstileToken.trim(),
      },
    );
  }

  static Future<void> submitSupportFeedback({
    required String message,
    String? name,
    String? phone,
    String? email,
    String? subject,
    int? rating,
    String? turnstileToken,
    String? customerId,
  }) async {
    final resolvedCustomerId = _resolveOptionalCustomerId(customerId);
    await _dio.post(
      '/support/feedback',
      data: {
        if (resolvedCustomerId != null) 'customer_id': resolvedCustomerId,
        'name': name?.trim(),
        'phone': phone?.trim(),
        'email': email?.trim(),
        'subject': subject?.trim(),
        'message': message.trim(),
        'rating': rating,
        'channel': kIsWeb ? 'WEB' : resolvePushPlatform(),
        if (turnstileToken != null && turnstileToken.trim().isNotEmpty)
          'turnstile_token': turnstileToken.trim(),
      },
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

  static Future<List<Map<String, dynamic>>> getProviders() async {
    try {
      final response = await _dio.get('/service-providers');
      final data = _readEnvelopeList(response);
      return List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item as Map)),
      );
    } catch (e) {
      debugPrint('Error getting service providers: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createProvider(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/service-providers', data: data);
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>?> updateProvider(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/service-providers/$id', data: data);
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>?> deleteProvider(String id) async {
    final response = await _dio.delete('/service-providers/$id');
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>?> getProviderPerformance(String id) async {
    final response = await _dio.get('/service-providers/$id/performance');
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>?> getProviderAnalytics() async {
    final response = await _dio.get('/service-providers/analytics');
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>?> getProviderWorkspace({
    String? providerId,
    String? providerType,
    String? businessId,
    int? limit,
  }) async {
    final response = await _dio.get(
      '/operations-queue/provider',
      queryParameters: {
        if (providerId != null) 'provider_id': providerId,
        if (providerType != null) 'provider_type': providerType,
        if (businessId != null) 'business_id': businessId,
        if (limit != null) 'limit': limit,
      },
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>?> getProviderPlatformWorkspace({
    String? providerId,
    String? providerType,
    String? businessId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = [
      providerId?.trim() ?? '',
      providerType?.trim() ?? '',
      businessId?.trim() ?? '',
    ].join('|');
    if (!forceRefresh &&
        _providerPlatformWorkspaceCache.containsKey(cacheKey)) {
      return Map<String, dynamic>.from(
        _providerPlatformWorkspaceCache[cacheKey]!,
      );
    }
    final response = await _dio.get(
      '/platform/workspace/provider',
      queryParameters: {
        if (providerId != null) 'provider_id': providerId,
        if (providerType != null) 'provider_type': providerType,
        if (businessId != null) 'business_id': businessId,
      },
    );
    final data = _readEnvelope(response);
    _providerPlatformWorkspaceCache[cacheKey] = Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>?> getCrmOperationsQueue({
    String? assignedTo,
    String? customerId,
    int? limit,
  }) async {
    final response = await _dio.get(
      '/operations-queue/crm',
      queryParameters: {
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (customerId != null) 'customer_id': customerId,
        if (limit != null) 'limit': limit,
      },
    );
    return _readEnvelope(response);
  }

  static Future<Map<String, dynamic>?> getAdminOperationsQueue({
    String? businessId,
    int? limit,
  }) async {
    final response = await _dio.get(
      '/operations-queue/admin',
      queryParameters: {
        if (businessId != null) 'business_id': businessId,
        if (limit != null) 'limit': limit,
      },
    );
    return _readEnvelope(response);
  }

  static Future<List<Map<String, dynamic>>> getBusinesses() async {
    try {
      final response = await _dio.get('/master-data/admin/businesses');
      final data = _readEnvelopeList(response);
      return List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item as Map)),
      );
    } catch (e) {
      debugPrint('Error getting businesses: $e');
      return [];
    }
  }
}
