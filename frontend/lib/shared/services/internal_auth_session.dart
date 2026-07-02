import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/shield_role.dart';
import 'active_auth_session.dart';
import 'api_service.dart';
import 'auth_redirect_notice.dart';
import 'device_identity_service.dart';

class InternalAuthSession extends ChangeNotifier {
  InternalAuthSession._();

  static final InternalAuthSession instance = InternalAuthSession._();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'internal_access_token';
  static const _refreshTokenKey = 'internal_refresh_token';
  static const _userIdKey = 'internal_user_id';
  static const _roleCodeKey = 'internal_role_code';
  static const _emailKey = 'internal_email';
  static const _displayNameKey = 'internal_display_name';
  static const _branchBusinessIdKey = 'internal_branch_business_id';

  bool _initialized = false;
  bool _isAuthenticated = false;
  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _roleCode;
  String? _email;
  String? _displayName;
  String? _branchBusinessId;

  void _trace(String message) {
    if (kDebugMode) {
      debugPrint('[InternalAuthSession] $message');
    }
  }

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get roleCode => _roleCode;
  String? get email => _email;
  String? get displayName => _displayName;
  String? get branchBusinessId => _branchBusinessId;
  SHIELDRole get homeRole => SHIELDRole.fromBackendRoleCode(_roleCode);

  Future<void> initialize() async {
    if (_initialized) {
      _trace('initialize skipped; already initialized');
      return;
    }

    _trace('initialize started');

    final values = await _storage.readAll();
    _accessToken = values[_accessTokenKey]?.trim();
    _refreshToken = values[_refreshTokenKey]?.trim();
    _userId = values[_userIdKey]?.trim();
    _roleCode = values[_roleCodeKey]?.trim();
    _email = values[_emailKey]?.trim();
    _displayName = values[_displayNameKey]?.trim();
    _branchBusinessId = values[_branchBusinessIdKey]?.trim();
    _trace(
      'token loaded: hasAccessToken=${_accessToken != null && _accessToken!.isNotEmpty}',
    );

    final activeKind = await ActiveAuthSession.getActiveKind();
    final canRestore =
        activeKind == null || activeKind == ShieldSessionKind.internal;
    if (canRestore && _accessToken != null && _accessToken!.isNotEmpty) {
      ApiService.configureAuthHandlers(
        onRefreshToken: _refreshAccessToken,
        onSessionExpired: _handleSessionExpired,
      );
      ApiService.setAccessToken(_accessToken!);
      final validated = await _validateOrRefreshSession();
      _trace('auth bootstrap completed; validated=$validated');
      if (!validated) {
        await _clearSessionStorage(notify: false);
      } else if (activeKind == null) {
        await ActiveAuthSession.setActiveKind(ShieldSessionKind.internal);
      }
    }

    _initialized = true;
    _trace('initialize completed');
    notifyListeners();
  }

  Future<void> completeLogin({
    required Map<String, dynamic> tokenPayload,
  }) async {
    final principal = tokenPayload['principal'] is Map<String, dynamic>
        ? tokenPayload['principal'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final profile = tokenPayload['profile'] is Map<String, dynamic>
        ? tokenPayload['profile'] as Map<String, dynamic>
        : const <String, dynamic>{};

    _accessToken = tokenPayload['accessToken']?.toString().trim();
    _refreshToken = tokenPayload['refreshToken']?.toString().trim();
    _userId = principal['userId']?.toString().trim();
    _roleCode = principal['roleCode']?.toString().trim();
    _email = principal['email']?.toString().trim();
    _branchBusinessId = principal['branchBusinessId']?.toString().trim();
    final firstName = profile['firstName']?.toString().trim() ?? '';
    final lastName = profile['lastName']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    _displayName = fullName.isNotEmpty ? fullName : (_email ?? 'Internal User');
    _isAuthenticated = _accessToken != null && _accessToken!.isNotEmpty;
    _trace(
      'completeLogin received token payload; hasAccessToken=$_isAuthenticated userId=${_userId ?? 'unknown'}',
    );

    if (_accessToken == null || _accessToken!.isEmpty) {
      throw StateError('Internal session token is missing.');
    }

    await ActiveAuthSession.setActiveKind(ShieldSessionKind.internal);
    ApiService.configureAuthHandlers(
      onRefreshToken: _refreshAccessToken,
      onSessionExpired: _handleSessionExpired,
    );
    ApiService.setAccessToken(_accessToken!);
    ApiService.setActiveCustomerId(null);
    _trace('api access token configured for internal session');

    await _storage.write(key: _accessTokenKey, value: _accessToken);
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: _refreshToken);
    }
    if (_userId != null && _userId!.isNotEmpty) {
      await _storage.write(key: _userIdKey, value: _userId);
    }
    if (_roleCode != null && _roleCode!.isNotEmpty) {
      await _storage.write(key: _roleCodeKey, value: _roleCode);
    }
    if (_email != null && _email!.isNotEmpty) {
      await _storage.write(key: _emailKey, value: _email);
    }
    if (_displayName != null && _displayName!.isNotEmpty) {
      await _storage.write(key: _displayNameKey, value: _displayName);
    }
    if (_branchBusinessId != null && _branchBusinessId!.isNotEmpty) {
      await _storage.write(
        key: _branchBusinessIdKey,
        value: _branchBusinessId,
      );
    }

    _trace('token stored and session persistence completed');
    notifyListeners();
  }

  Future<void> signOut() async {
    final refreshToken = _refreshToken?.trim();
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
      final payload = await ApiService.getAuthenticatedProfile();
      _hydrateProfile(payload);
      _isAuthenticated = true;
      _trace('validateOrRefreshSession succeeded with existing token');
      return true;
    } catch (_) {
      _trace('validateOrRefreshSession failed; attempting refresh');
      final refreshed = await _refreshAccessToken();
      if (refreshed == null || refreshed.isEmpty) {
        _trace('refresh access token failed');
        return false;
      }
      try {
        final payload = await ApiService.getAuthenticatedProfile();
        _hydrateProfile(payload);
        _isAuthenticated = true;
        _trace('validateOrRefreshSession succeeded after refresh');
        return true;
      } catch (_) {
        _trace('validateOrRefreshSession still failed after refresh');
        return false;
      }
    }
  }

  Future<String?> _refreshAccessToken() async {
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
      final principal = payload['principal'] is Map<String, dynamic>
          ? payload['principal'] as Map<String, dynamic>
          : const <String, dynamic>{};
      _accessToken = payload['accessToken']?.toString().trim();
      _refreshToken =
          payload['refreshToken']?.toString().trim() ?? refreshToken;
      _userId = principal['userId']?.toString().trim() ?? _userId;
      _roleCode = principal['roleCode']?.toString().trim() ?? _roleCode;
      _email = principal['email']?.toString().trim() ?? _email;
      _branchBusinessId =
          principal['branchBusinessId']?.toString().trim() ?? _branchBusinessId;

      if (_accessToken == null || _accessToken!.isEmpty) {
        return null;
      }

      await ActiveAuthSession.setActiveKind(ShieldSessionKind.internal);
      ApiService.configureAuthHandlers(
        onRefreshToken: _refreshAccessToken,
        onSessionExpired: _handleSessionExpired,
      );
      ApiService.setAccessToken(_accessToken!);
      ApiService.setActiveCustomerId(null);
      _isAuthenticated = true;
      _trace('refreshAccessToken completed and ApiService token updated');

      await _storage.write(key: _accessTokenKey, value: _accessToken);
      await _storage.write(key: _refreshTokenKey, value: _refreshToken);
      if (_userId != null && _userId!.isNotEmpty) {
        await _storage.write(key: _userIdKey, value: _userId);
      }
      if (_roleCode != null && _roleCode!.isNotEmpty) {
        await _storage.write(key: _roleCodeKey, value: _roleCode);
      }
      if (_email != null && _email!.isNotEmpty) {
        await _storage.write(key: _emailKey, value: _email);
      }
      if (_branchBusinessId != null && _branchBusinessId!.isNotEmpty) {
        await _storage.write(
          key: _branchBusinessIdKey,
          value: _branchBusinessId,
        );
      }

      notifyListeners();
      return _accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSessionExpired() async {
    _trace('session expired handler invoked');
    AuthRedirectNotice.instance.showSessionExpired(
      sessionKind: ShieldSessionKind.internal,
      message:
          'Your SHIELD staff session expired or is no longer valid. Please sign in again with your approved internal account.',
    );
    await _clearSessionStorage();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  void _hydrateProfile(Map<String, dynamic> payload) {
    final principal = payload['principal'] is Map<String, dynamic>
        ? payload['principal'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final profile = payload['profile'] is Map<String, dynamic>
        ? payload['profile'] as Map<String, dynamic>
        : const <String, dynamic>{};
    _userId = principal['userId']?.toString().trim() ?? _userId;
    _roleCode = principal['roleCode']?.toString().trim() ?? _roleCode;
    _email = principal['email']?.toString().trim() ?? _email;
    _branchBusinessId =
        principal['branchBusinessId']?.toString().trim() ?? _branchBusinessId;
    final firstName = profile['firstName']?.toString().trim() ?? '';
    final lastName = profile['lastName']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) {
      _displayName = fullName;
    }
  }

  Future<void> _clearSessionStorage({bool notify = true}) async {
    _trace('clearing session storage');
    _isAuthenticated = false;
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _roleCode = null;
    _email = null;
    _displayName = null;
    _branchBusinessId = null;

    final activeKind = await ActiveAuthSession.getActiveKind();
    if (activeKind == ShieldSessionKind.internal) {
      await ActiveAuthSession.clearActiveKind();
      ApiService.clearAccessToken();
      ApiService.setActiveCustomerId(null);
    }

    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _roleCodeKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _displayNameKey);
    await _storage.delete(key: _branchBusinessIdKey);

    if (notify) {
      notifyListeners();
    }
  }
}
