import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';
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

  bool _initialized = false;
  bool _isAuthenticated = false;
  String? _accessToken;
  String? _refreshToken;
  String? _mobile;
  String? _customerId;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _isAuthenticated;
  String? get mobile => _mobile;
  String? get customerId => _customerId;

  Future<void> initialize() async {
    ApiService.configureAuthHandlers(
      onRefreshToken: _refreshAccessToken,
      onSessionExpired: _handleSessionExpired,
    );

    if (_initialized) {
      return;
    }

    final values = await _storage.readAll();
    _accessToken = values[_accessTokenKey]?.trim();
    _refreshToken = values[_refreshTokenKey]?.trim();
    _mobile = values[_mobileKey]?.trim();
    _customerId = values[_customerIdKey]?.trim();

    if (_accessToken != null && _accessToken!.isNotEmpty) {
      ApiService.setAccessToken(_accessToken!);
      ApiService.setActiveCustomerId(_customerId);

      final validated = await _validateOrRefreshSession();
      if (!validated) {
        await _clearSessionStorage(notify: false);
      }
    }

    _initialized = true;
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

    if (_accessToken != null) {
      await _storage.write(key: _accessTokenKey, value: _accessToken);
    }
    if (_refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: _refreshToken);
    }
    if (_mobile != null && _mobile!.isNotEmpty) {
      await _storage.write(key: _mobileKey, value: _mobile);
    }
    if (_customerId != null && _customerId!.isNotEmpty) {
      await _storage.write(key: _customerIdKey, value: _customerId);
    }

    notifyListeners();
  }

  Future<void> signOut() async {
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

  Future<bool> _validateOrRefreshSession() async {
    try {
      await ApiService.getAuthenticatedProfile();
      _isAuthenticated = true;
      return true;
    } catch (_) {
      final refreshed = await _refreshAccessToken();
      if (refreshed == null || refreshed.isEmpty) {
        return false;
      }
      try {
        await ApiService.getAuthenticatedProfile();
        _isAuthenticated = true;
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<String?> _refreshAccessToken() async {
    final previousCustomerId = _customerId;
    final refreshToken = _refreshToken?.trim();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

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

      await _storage.write(key: _accessTokenKey, value: _accessToken);
      await _storage.write(key: _refreshTokenKey, value: _refreshToken);
      if (_customerId != null && _customerId!.isNotEmpty) {
        await _storage.write(key: _customerIdKey, value: _customerId);
      }
      if (_mobile != null && _mobile!.isNotEmpty) {
        await _storage.write(key: _mobileKey, value: _mobile);
      }

      notifyListeners();
      return _accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSessionExpired() async {
    await _clearSessionStorage();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  Future<void> _clearSessionStorage({bool notify = true}) async {
    final previousCustomerId = _customerId;
    _isAuthenticated = false;
    _accessToken = null;
    _refreshToken = null;
    _mobile = null;
    _customerId = null;

    ApiService.clearAccessToken();
    ApiService.setActiveCustomerId(null);

    await CustomerCacheService.clearForCustomer(previousCustomerId);

    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _mobileKey);
    await _storage.delete(key: _customerIdKey);

    if (notify) {
      notifyListeners();
    }
  }
}
