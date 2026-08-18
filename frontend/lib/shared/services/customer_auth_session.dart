import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'active_auth_session.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'auth_redirect_notice.dart';
import 'customer_cache_service.dart';
import 'device_identity_service.dart';

class CustomerAuthSession extends ChangeNotifier {
  CustomerAuthSession._();

  static final CustomerAuthSession instance = CustomerAuthSession._();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'customer_access_token';
  static const _refreshTokenKey = 'customer_refresh_token';
  static const _mobileKey = 'customer_mobile';
  static const _customerIdKey = 'customer_id';
  static const _sessionSnapshotKey = 'customer_auth_session_v1';
  static const _pendingReferralCodeKey = 'pending_referral_code';

  bool _initialized = false;
  bool _isAuthenticated = false;
  String? _accessToken;
  String? _refreshToken;
  String? _mobile;
  String? _customerId;
  String? _pendingReferralCode;
  bool _lastRefreshWasAuthInvalid = false;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _isAuthenticated;
  String? get mobile => _mobile;
  String? get customerId => _customerId;
  String? get pendingReferralCode => _pendingReferralCode;

  Future<void> setPendingReferralCode(String code) async {
    final cleaned = code.trim();
    if (cleaned.isEmpty) return;
    _pendingReferralCode = cleaned;
    await _storage.write(key: _pendingReferralCodeKey, value: cleaned);
    notifyListeners();
  }

  Future<String?> getPendingReferralCode() async {
    if (_pendingReferralCode != null) return _pendingReferralCode;
    _pendingReferralCode = await _storage.read(key: _pendingReferralCodeKey);
    return _pendingReferralCode;
  }

  Future<void> clearPendingReferralCode() async {
    _pendingReferralCode = null;
    await _storage.delete(key: _pendingReferralCodeKey);
    notifyListeners();
  }

  Future<void> initialize() async {
    debugPrint('CUSTOMER_SESSION_RESTORE_STARTED');
    ApiService.configureAuthHandlers(
      onRefreshToken: _refreshAccessToken,
      onSessionExpired: _handleSessionExpired,
    );

    if (_initialized) {
      return;
    }

    final values = await _storage.readAll();
    final snapshot = _readSessionSnapshot(values[_sessionSnapshotKey]);
    _accessToken =
        snapshot[_accessTokenKey]?.trim() ?? values[_accessTokenKey]?.trim();
    _refreshToken =
        snapshot[_refreshTokenKey]?.trim() ?? values[_refreshTokenKey]?.trim();
    _mobile = snapshot[_mobileKey]?.trim() ?? values[_mobileKey]?.trim();
    _customerId =
        snapshot[_customerIdKey]?.trim() ?? values[_customerIdKey]?.trim();
    debugPrint(
      'CUSTOMER_SESSION_STORAGE_FOUND access=${_accessToken?.isNotEmpty == true} refresh=${_refreshToken?.isNotEmpty == true} customer=${_customerId?.isNotEmpty == true}',
    );

    final activeKind = await ActiveAuthSession.getActiveKind();
    final canRestore =
        activeKind == null || activeKind == ShieldSessionKind.customer;
    final hasAccess = _accessToken?.isNotEmpty == true;
    final hasRefresh = _refreshToken?.isNotEmpty == true;
    if (canRestore && (hasAccess || hasRefresh)) {
      _isAuthenticated = true;
      if (hasAccess) {
        ApiService.setAccessToken(_accessToken!);
        debugPrint('CUSTOMER_ACCESS_STAGED');
      }
      ApiService.setActiveCustomerId(_customerId);

      final validated = hasAccess
          ? await _validateOrRefreshSession()
          : await _restoreFromRefreshToken();
      if (!validated && _lastRefreshWasAuthInvalid) {
        await _clearSessionStorage(notify: true, reason: 'auth_invalid');
      } else if (validated || hasRefresh) {
        // Retain the durable session on temporary backend/network failures. A
        // subsequent protected request can retry the existing single-flight
        // refresh instead of forcing an OTP journey.
        _isAuthenticated = true;
        debugPrint('CUSTOMER_SESSION_RETAINED');
      }
      if (_isAuthenticated && activeKind == null) {
        await ActiveAuthSession.setActiveKind(ShieldSessionKind.customer);
      }
    }

    // DEV BYPASS MODE: Default authenticated state for localhost / development.
    // PRODUCTION CODE: Comment out or set _isAuthenticated = false for strict production auth.
    if (!_isAuthenticated) {
      _isAuthenticated = true;
      _mobile ??= '9000000002';
      _customerId ??= '1';
      _accessToken ??= 'mock-bypass-access-token';
      ApiService.setAccessToken(_accessToken!);
      ApiService.setActiveCustomerId(_customerId);
    }

    _initialized = true;
    debugPrint(
      'CUSTOMER_SESSION_RESTORE_COMPLETE authenticated=$_isAuthenticated',
    );
    notifyListeners();
  }

  Future<void> completeLogin({
    required Map<String, dynamic> tokenPayload,
    String? fallbackMobile,
  }) async {
    final previousCustomerId = _customerId;
    _accessToken = tokenPayload['accessToken']?.toString().trim();
    _refreshToken = tokenPayload['refreshToken']?.toString().trim();
    final principal = tokenPayload['principal'] is Map<String, dynamic>
        ? tokenPayload['principal'] as Map<String, dynamic>
        : const <String, dynamic>{};

    _mobile = principal['mobile']?.toString().trim().isNotEmpty == true
        ? principal['mobile']?.toString().trim()
        : fallbackMobile?.trim();
    _customerId = principal['customerId']?.toString().trim();
    _isAuthenticated = _accessToken != null && _accessToken!.isNotEmpty;

    if (previousCustomerId != null &&
        previousCustomerId.isNotEmpty &&
        previousCustomerId != _customerId) {
      await CustomerCacheService.clearForCustomer(previousCustomerId);
    }

    if (_accessToken != null) {
      ApiService.setAccessToken(_accessToken!);
    } else {
      ApiService.clearAccessToken();
    }
    ApiService.setActiveCustomerId(_customerId);
    await ActiveAuthSession.setActiveKind(ShieldSessionKind.customer);

    await _persistSessionValues();

    notifyListeners();
  }

  Future<void> signOut() async {
    await _deactivateCurrentPushToken();
    final refreshToken = _refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await ApiService.logout(
          refreshToken,
          deviceId: await DeviceIdentityService.getInstallationId(),
          deviceLabel: DeviceIdentityService.defaultDeviceLabel(),
          platform: DeviceIdentityService.resolvePlatform(),
        );
      } catch (_) {}
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    await _clearSessionStorage();
  }

  Future<void> _deactivateCurrentPushToken() async {
    if (!AppConfig.enableNotifications) return;
    try {
      final token = kIsWeb
          ? await FirebaseMessaging.instance.getToken(
              vapidKey: AppConfig.firebaseWebVapidKey,
            )
          : await FirebaseMessaging.instance.getToken();
      if (token != null && token.trim().isNotEmpty) {
        await ApiService.deactivatePushToken(token.trim());
      }
    } catch (error) {
      debugPrint(
        'SHIELD push token deactivation skipped during sign-out: $error',
      );
    }
  }

  Future<bool> _validateOrRefreshSession() async {
    try {
      await ApiService.getAuthenticatedProfile();
      _isAuthenticated = true;
      return true;
    } catch (error) {
      // ApiService owns the single-flight refresh and one authenticated retry.
      // A second manual refresh/profile cycle here previously duplicated /auth/me
      // traffic after an expired or rejected access token.
      if (_isTransientFailure(error)) {
        debugPrint(
          'CUSTOMER_REFRESH_TRANSIENT_FAILURE status=${_statusCode(error)}',
        );
        return false;
      }
      return false;
    }
  }

  Future<bool> _restoreFromRefreshToken() async {
    final token = await _refreshAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> _refreshAccessToken() async {
    final previousCustomerId = _customerId;
    final refreshToken = _refreshToken?.trim();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    _lastRefreshWasAuthInvalid = false;
    debugPrint('CUSTOMER_REFRESH_STARTED');
    try {
      final payload = await ApiService.refreshSession(
        refreshToken,
        await DeviceIdentityService.getInstallationId(),
        DeviceIdentityService.defaultDeviceLabel(),
        DeviceIdentityService.resolvePlatform(),
      );
      _accessToken = payload['accessToken']?.toString().trim();
      _refreshToken =
          payload['refreshToken']?.toString().trim() ?? refreshToken;
      final principal = payload['principal'] is Map<String, dynamic>
          ? payload['principal'] as Map<String, dynamic>
          : const <String, dynamic>{};
      _customerId = principal['customerId']?.toString().trim() ?? _customerId;
      _mobile = principal['mobile']?.toString().trim() ?? _mobile;

      if (_accessToken == null || _accessToken!.isEmpty) {
        return null;
      }

      ApiService.setAccessToken(_accessToken!);
      ApiService.setActiveCustomerId(_customerId);
      _isAuthenticated = true;

      if (previousCustomerId != null &&
          previousCustomerId.isNotEmpty &&
          previousCustomerId != _customerId) {
        await CustomerCacheService.clearForCustomer(previousCustomerId);
      }

      // Persist the rotated refresh token with the related session values as
      // one secure-storage operation, before reporting refresh success.
      await _persistSessionValues();
      await ActiveAuthSession.setActiveKind(ShieldSessionKind.customer);

      debugPrint('CUSTOMER_REFRESH_SUCCESS');
      notifyListeners();
      return _accessToken;
    } catch (error) {
      _lastRefreshWasAuthInvalid = _isDefinitiveAuthInvalid(error);
      if (_lastRefreshWasAuthInvalid) {
        debugPrint(
          'CUSTOMER_REFRESH_AUTH_INVALID status=${_statusCode(error)}',
        );
      } else {
        debugPrint(
          'CUSTOMER_REFRESH_TRANSIENT_FAILURE status=${_statusCode(error)}',
        );
      }
      // A failed refresh is not automatically an invalid session. Returning
      // the staged token prevents the interceptor from clearing durable
      // credentials on a timeout, rate-limit, or backend outage; the retried
      // request will still surface its own failure to the caller.
      return _lastRefreshWasAuthInvalid ? null : _accessToken;
    }
  }

  Future<void> _handleSessionExpired() async {
    AuthRedirectNotice.instance.showSessionExpired(
      sessionKind: ShieldSessionKind.customer,
      message:
          'Your SHIELD member session expired or is no longer valid. Please sign in again to continue securely.',
    );
    await _clearSessionStorage(reason: 'session_expired');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  bool _isDefinitiveAuthInvalid(Object error) =>
      error is DioException && error.response?.statusCode == 401;

  bool _isTransientFailure(Object error) {
    if (error is! DioException) return false;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    return const {
      408,
      429,
      500,
      502,
      503,
      504,
    }.contains(error.response?.statusCode);
  }

  int? _statusCode(Object error) =>
      error is DioException ? error.response?.statusCode : null;

  Future<void> _persistSessionValues() async {
    final values = <String, String>{};
    if (_accessToken?.isNotEmpty == true) {
      values[_accessTokenKey] = _accessToken!;
    }
    if (_refreshToken?.isNotEmpty == true) {
      values[_refreshTokenKey] = _refreshToken!;
    }
    if (_mobile?.isNotEmpty == true) {
      values[_mobileKey] = _mobile!;
    }
    if (_customerId?.isNotEmpty == true) {
      values[_customerIdKey] = _customerId!;
    }
    // flutter_secure_storage 9.x does not offer writeAll. Store the complete
    // session first in one encrypted record, then mirror the established keys
    // for compatibility with older installs. If the process stops midway, the
    // snapshot still has the complete, rotated credential set.
    await _storage.write(key: _sessionSnapshotKey, value: jsonEncode(values));
    for (final entry in values.entries) {
      await _storage.write(key: entry.key, value: entry.value);
    }
  }

  Map<String, String> _readSessionSnapshot(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return const <String, String>{};
    }
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map) return const <String, String>{};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString().trim()),
      );
    } catch (_) {
      debugPrint('CUSTOMER_SESSION_SNAPSHOT_INVALID');
      return const <String, String>{};
    }
  }

  Future<void> _clearSessionStorage({
    bool notify = true,
    String reason = 'explicit_logout',
  }) async {
    debugPrint('CUSTOMER_SESSION_CLEARED reason=$reason');
    final previousCustomerId = _customerId;
    _isAuthenticated = false;
    _accessToken = null;
    _refreshToken = null;
    _mobile = null;
    _customerId = null;

    final activeKind = await ActiveAuthSession.getActiveKind();
    if (activeKind == ShieldSessionKind.customer) {
      await ActiveAuthSession.clearActiveKind();
      ApiService.clearAccessToken();
      ApiService.setActiveCustomerId(null);
    }

    await CustomerCacheService.clearForCustomer(previousCustomerId);

    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _mobileKey);
    await _storage.delete(key: _customerIdKey);
    await _storage.delete(key: _sessionSnapshotKey);

    if (notify) {
      notifyListeners();
    }
  }
}
