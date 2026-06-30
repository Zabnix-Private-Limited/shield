import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/services/device_identity_service.dart';
import '../../../../../shared/services/internal_auth_session.dart';

class InternalAuthRepository {
  InternalAuthRepository._();

  static final InternalAuthRepository instance = InternalAuthRepository._();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();
    UserCredential userCredential;
    if (kIsWeb) {
      userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
    } else {
      userCredential = await _firebaseAuth.signInWithProvider(googleProvider);
    }

    final firebaseUser = userCredential.user ?? _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw StateError('Google sign-in completed without a Firebase user.');
    }

    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw StateError('Unable to read the Google sign-in token.');
    }

    try {
      final payload = await ApiService.internalLogin(
        firebaseIdToken: firebaseIdToken,
        deviceId: await DeviceIdentityService.getInstallationId(),
        deviceLabel: DeviceIdentityService.defaultDeviceLabel(),
        platform: DeviceIdentityService.resolvePlatform(),
      );
      final accessToken = payload['accessToken']?.toString().trim() ?? '';
      if (accessToken.isEmpty) {
        throw StateError('Internal sign-in did not return an access token.');
      }
      ApiService.setAccessToken(accessToken);
      ApiService.setActiveCustomerId(null);
      final profile = await ApiService.getAuthenticatedProfile();
      payload['profile'] = profile['profile'];
      await InternalAuthSession.instance.completeLogin(tokenPayload: payload);
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map
          ? (data['message'] ?? data['msg'] ?? '').toString()
          : '';
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
      ApiService.clearAccessToken();
      ApiService.setActiveCustomerId(null);
      if (message.isNotEmpty) {
        throw StateError(message);
      }
      throw StateError('Internal sign-in failed right now. Please try again.');
    } catch (_) {
      ApiService.clearAccessToken();
      ApiService.setActiveCustomerId(null);
      rethrow;
    }
  }
}
