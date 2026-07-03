import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/services/device_identity_service.dart';
import '../../../../../shared/services/internal_auth_session.dart';

enum InternalAuthSignInResult { completed, redirecting }

class InternalAuthRepository {
  InternalAuthRepository._();

  static final InternalAuthRepository instance = InternalAuthRepository._();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const <String>['email'],
  );

  void _trace(String message) {
    if (kDebugMode) {
      debugPrint('[ProviderAuthLogin] $message');
    }
  }

  Future<InternalAuthSignInResult> signInWithGoogle() async {
    _trace('google sign-in started');
    final googleProvider = GoogleAuthProvider();
    if (kIsWeb) {
      await _firebaseAuth.signInWithRedirect(googleProvider);
      return InternalAuthSignInResult.redirecting;
    }
    final userCredential = await _signInWithNativeGoogleOrProvider(
      googleProvider,
    );

    final firebaseUser = userCredential.user ?? _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw StateError('Google sign-in completed without a Firebase user.');
    }

    await _completeFirebaseLogin(firebaseUser);
    return InternalAuthSignInResult.completed;
  }

  Future<bool> resumeRedirectSignIn() async {
    if (!kIsWeb) {
      return false;
    }
    final userCredential = await _firebaseAuth.getRedirectResult();
    final firebaseUser = userCredential.user ?? _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return false;
    }
    await _completeFirebaseLogin(firebaseUser);
    return true;
  }

  Future<UserCredential> _signInWithNativeGoogleOrProvider(
    GoogleAuthProvider googleProvider,
  ) async {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(
            code: 'sign_in_canceled',
            message: 'Google sign-in was cancelled.',
          );
        }
        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken?.trim();
        if (idToken == null || idToken.isEmpty) {
          throw StateError('Unable to read the Google sign-in token.');
        }
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: idToken,
        );
        return _firebaseAuth.signInWithCredential(credential);
      } catch (error) {
        _trace(
          'native Google sign-in fallback to Firebase provider flow: $error',
        );
      }
    }

    return _firebaseAuth.signInWithProvider(googleProvider);
  }

  Future<void> _completeFirebaseLogin(User firebaseUser) async {

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
      _trace('login completed; access token received (${accessToken.length} chars)');
      ApiService.setAccessToken(accessToken);
      _trace('api access token primed before profile bootstrap');
      ApiService.setActiveCustomerId(null);
      final profile = await ApiService.getAuthenticatedProfile();
      _trace('authenticated profile bootstrap completed');
      payload['profile'] = profile['profile'];
      await InternalAuthSession.instance.completeLogin(tokenPayload: payload);
      _trace('internal auth session completeLogin finished');
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map
          ? (data['message'] ?? data['msg'] ?? '').toString()
          : '';
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
      try {
        await _googleSignIn.signOut();
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
