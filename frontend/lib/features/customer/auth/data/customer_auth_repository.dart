import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/services/customer_auth_session.dart';
import '../../../../../shared/services/device_identity_service.dart';
import '../../../../../shared/services/firebase_bootstrap_service.dart';

enum CustomerAuthOutcome { authenticated, registrationRequired }
enum CustomerPhoneVerificationStartResult {
  codeSent,
  authenticated,
  registrationRequired,
}

class CustomerAuthRepository {
  CustomerAuthRepository._();

  static final CustomerAuthRepository instance = CustomerAuthRepository._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  ConfirmationResult? _webConfirmationResult;
  String? _verificationId;
  int? _forceResendingToken;
  String? _pendingPhoneNumber;
  DateTime? _resendAllowedAt;

  String? get pendingPhoneNumber => _pendingPhoneNumber;
  DateTime? get resendAllowedAt => _resendAllowedAt;

  Future<CustomerPhoneVerificationStartResult> startPhoneVerification(
    String rawPhoneNumber,
  ) async {
    final phoneNumber = _normalizeIndianPhone(rawPhoneNumber);
    _pendingPhoneNumber = phoneNumber;
    _resendAllowedAt = DateTime.now().add(const Duration(seconds: 30));
    _verificationId = null;
    _webConfirmationResult = null;

    if (kIsWeb) {
      if (_isUnsupportedLocalWebHost(Uri.base.host)) {
        throw FirebaseAuthException(
          code: 'web-phone-auth-domain',
          message:
              'Firebase web OTP does not work on localhost. Open SHIELD on an authorized domain to continue.',
        );
      }

      _webConfirmationResult = await _firebaseAuth.signInWithPhoneNumber(
        phoneNumber,
      );
      return CustomerPhoneVerificationStartResult.codeSent;
    }

    final completer = Completer<CustomerPhoneVerificationStartResult>();
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _forceResendingToken,
      verificationCompleted: (credential) async {
        try {
          await _firebaseAuth.signInWithCredential(credential);
          final outcome = await _completeVerifiedCustomerSession();
          if (!completer.isCompleted) {
            completer.complete(
              outcome == CustomerAuthOutcome.authenticated
                  ? CustomerPhoneVerificationStartResult.authenticated
                  : CustomerPhoneVerificationStartResult.registrationRequired,
            );
          }
        } catch (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      codeSent: (verificationId, forceResendingToken) {
        _verificationId = verificationId;
        _forceResendingToken = forceResendingToken;
        if (!completer.isCompleted) {
          completer.complete(CustomerPhoneVerificationStartResult.codeSent);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
    return completer.future;
  }

  Future<void> resendOtp() async {
    final phoneNumber = _pendingPhoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw StateError('Phone verification has not been started.');
    }
    await startPhoneVerification(phoneNumber);
  }

  Future<CustomerAuthOutcome> verifyOtp(String otpCode) async {
    final normalizedOtp = otpCode.trim();
    if (normalizedOtp.length != 6) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'Enter the 6-digit OTP.',
      );
    }

    UserCredential userCredential;
    if (kIsWeb) {
      final confirmation = _webConfirmationResult;
      if (confirmation == null) {
        throw StateError('OTP session expired. Start again.');
      }
      userCredential = await confirmation.confirm(normalizedOtp);
    } else {
      final verificationId = _verificationId;
      if (verificationId == null || verificationId.isEmpty) {
        throw StateError('OTP session expired. Start again.');
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: normalizedOtp,
      );
      userCredential = await _firebaseAuth.signInWithCredential(credential);
    }

    final firebaseUser = userCredential.user ?? _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw StateError('Phone verification completed without a Firebase user.');
    }

    return _completeVerifiedCustomerSession(firebaseUser: firebaseUser);
  }

  Future<CustomerAuthOutcome?> tryCompleteAutoVerifiedSession() async {
    if (_pendingPhoneNumber == null || _pendingPhoneNumber!.isEmpty) {
      return null;
    }
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    return _completeVerifiedCustomerSession(firebaseUser: firebaseUser);
  }

  Future<CustomerAuthOutcome> _completeVerifiedCustomerSession({
    User? firebaseUser,
  }) async {
    final resolvedUser = firebaseUser ?? _firebaseAuth.currentUser;
    if (resolvedUser == null) {
      throw StateError('Phone verification completed without a Firebase user.');
    }

    final firebaseIdToken = await resolvedUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw StateError('Unable to read the verified Firebase token.');
    }

    final deviceId = await DeviceIdentityService.getInstallationId();
    final deviceLabel = DeviceIdentityService.defaultDeviceLabel();
    final platform = DeviceIdentityService.resolvePlatform();

    try {
      final payload = await ApiService.customerLogin(
        firebaseIdToken: firebaseIdToken,
        deviceId: deviceId,
        deviceLabel: deviceLabel,
        platform: platform,
      );
      await CustomerAuthSession.instance.completeLogin(
        tokenPayload: payload,
        fallbackMobile: _pendingPhoneNumber,
      );
      await FirebaseBootstrapService.registerCurrentPushToken();
      _clearPendingVerification();
      return CustomerAuthOutcome.authenticated;
    } on DioException catch (error) {
      final body = error.response?.data;
      final message = body is Map
          ? (body['message'] ?? body['msg'] ?? '').toString()
          : '';
      if (error.response?.statusCode == 401 &&
          message.contains('not provisioned')) {
        return CustomerAuthOutcome.registrationRequired;
      }
      if (message.isNotEmpty) {
        throw StateError(message);
      }
      throw StateError('OTP verification failed right now. Please try again.');
    }
  }

  Future<void> registerCustomer({
    required String name,
    required DateTime dob,
    required String gender,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw StateError('Customer verification session expired.');
    }

    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw StateError('Unable to read the verified Firebase token.');
    }
    final deviceId = await DeviceIdentityService.getInstallationId();
    final deviceLabel = DeviceIdentityService.defaultDeviceLabel();
    final platform = DeviceIdentityService.resolvePlatform();
    final payload = await ApiService.customerRegister(
      firebaseIdToken: firebaseIdToken,
      name: name,
      dob: dob,
      gender: gender,
      deviceId: deviceId,
      deviceLabel: deviceLabel,
      platform: platform,
    );

    await CustomerAuthSession.instance.completeLogin(
      tokenPayload: payload,
      fallbackMobile: _pendingPhoneNumber,
    );
    await FirebaseBootstrapService.registerCurrentPushToken();
    _clearPendingVerification();
  }

  void resetFlow() {
    _clearPendingVerification();
  }

  void _clearPendingVerification() {
    _webConfirmationResult = null;
    _verificationId = null;
    _pendingPhoneNumber = null;
    _resendAllowedAt = null;
  }

  bool _isUnsupportedLocalWebHost(String host) {
    final normalized = host.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '0.0.0.0' ||
        normalized == '::1';
  }

  String _normalizeIndianPhone(String rawPhoneNumber) {
    final digits = rawPhoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91$digits';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    if (rawPhoneNumber.trim().startsWith('+')) {
      return rawPhoneNumber.trim();
    }
    throw FirebaseAuthException(
      code: 'invalid-phone-number',
      message: 'Enter a valid Indian mobile number.',
    );
  }
}
