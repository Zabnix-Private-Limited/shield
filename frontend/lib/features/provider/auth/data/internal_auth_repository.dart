import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../../shared/services/api_service.dart';
import '../../../../../shared/services/device_identity_service.dart';
import '../../../../../shared/services/internal_auth_redirect_state.dart';
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
    debugPrint('[ProviderAuthLogin] $message');
  }

  Future<InternalAuthSignInResult> signInWithGoogle() async {
    _trace('1. Google Sign-In started');
    final googleProvider = GoogleAuthProvider();
    if (kIsWeb) {
      try {
        _trace('web sign-in using Firebase popup flow');
        final userCredential = await _firebaseAuth.signInWithPopup(
          googleProvider,
        );
        _trace('Firebase popup completed');
        final firebaseUser = userCredential.user ?? _firebaseAuth.currentUser;
        if (firebaseUser == null) {
          throw StateError(
            'Google sign-in popup completed without a Firebase user.',
          );
        }
        await _completeFirebaseLogin(firebaseUser);
        return InternalAuthSignInResult.completed;
      } on FirebaseAuthException catch (error, stackTrace) {
        final shouldFallbackToRedirect =
            error.code == 'popup-blocked' ||
            error.code == 'popup_closed_by_user' ||
            error.code == 'popup-closed-by-user' ||
            error.code == 'cancelled-popup-request' ||
            error.code == 'web-storage-unsupported' ||
            error.code == 'web-context-cancelled';
        _trace(
          'web popup sign-in failed code=${error.code} message=${error.message}',
        );
        debugPrintStack(
          label: '[ProviderAuthLogin] popup sign-in stack',
          stackTrace: stackTrace,
        );
        if (!shouldFallbackToRedirect) {
          rethrow;
        }
        _trace('falling back to Firebase redirect flow');
        markPendingInternalAuthRedirect();
        await _firebaseAuth.signInWithRedirect(googleProvider);
        _trace('Firebase redirect initiated; browser should leave SHIELD now');
        return InternalAuthSignInResult.redirecting;
      }
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
    if (!hasPendingInternalAuthRedirect()) {
      _trace('redirect resume skipped because SHIELD did not initiate redirect fallback');
      return false;
    }
    _trace('redirect resume started');
    try {
      final userCredential = await _firebaseAuth.getRedirectResult();
      _trace('redirect result received from Firebase');
      final firebaseUser = userCredential.user ?? _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        _trace('redirect resume finished without a Firebase user');
        clearPendingInternalAuthRedirect();
        return false;
      }
      _trace('2. Firebase user received from redirect: ${firebaseUser.uid}');
      await _completeFirebaseLogin(firebaseUser);
      clearPendingInternalAuthRedirect();
      return true;
    } catch (error, stackTrace) {
      clearPendingInternalAuthRedirect();
      _trace('redirect resume threw: $error');
      debugPrintStack(
        label: '[ProviderAuthLogin] redirect resume stack',
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
    _trace('2. Firebase user received: ${firebaseUser.uid}');

    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw StateError('Unable to read the Google sign-in token.');
    }

    try {
      _trace('3. Requesting backend session');
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
      _trace(
        '4. Backend session created; access token received (${accessToken.length} chars)',
      );
      ApiService.setAccessToken(accessToken);
      _trace('api access token primed before profile bootstrap');
      ApiService.setActiveCustomerId(null);
      _trace('5. Fetching current internal user');
      final profile = await ApiService.getAuthenticatedProfile();
      final profileMap = profile['profile'] is Map<String, dynamic>
          ? profile['profile'] as Map<String, dynamic>
          : const <String, dynamic>{};
      _trace(
        '6. Internal user loaded; role=${payload['principal']?['roleCode'] ?? 'unknown'} email=${profileMap['email'] ?? payload['principal']?['email'] ?? 'unknown'}',
      );
      payload['profile'] = profile['profile'];
      _trace('7. Saving session');
      await InternalAuthSession.instance.completeLogin(tokenPayload: payload);
      _trace('session saved; internal auth session completeLogin finished');
    } on DioException catch (error, stackTrace) {
      final data = error.response?.data;
      final message = data is Map
          ? (data['message'] ?? data['msg'] ?? '').toString()
          : '';
      _trace(
        'backend auth request failed status=${error.response?.statusCode} message=${error.message}',
      );
      debugPrintStack(
        label: '[ProviderAuthLogin] backend auth stack',
        stackTrace: stackTrace,
      );
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
    } catch (error, stackTrace) {
      _trace('completeFirebaseLogin crashed: $error');
      debugPrintStack(
        label: '[ProviderAuthLogin] completeFirebaseLogin stack',
        stackTrace: stackTrace,
      );
      ApiService.clearAccessToken();
      ApiService.setActiveCustomerId(null);
      rethrow;
    }
  }
}
