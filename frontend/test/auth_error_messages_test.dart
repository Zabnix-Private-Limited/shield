import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/services/auth_error_messages.dart';

void main() {
  group('AuthErrorMessages.resolve', () {
    test('maps invalid otp code to a specific customer message', () {
      final message = AuthErrorMessages.resolve(
        FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'bad code',
        ),
        flow: AuthFlow.customerOtp,
      );

      expect(
        message,
        'The OTP you entered is invalid. Check the 6-digit code and try again.',
      );
    });

    test('maps cancelled Google sign-in to a specific internal message', () {
      final message = AuthErrorMessages.resolve(
        FirebaseAuthException(
          code: 'sign_in_canceled',
          message: 'cancelled',
        ),
        flow: AuthFlow.internalGoogle,
      );

      expect(
        message,
        'Google sign-in was cancelled before SHIELD access could be completed.',
      );
    });

    test('maps unprovisioned internal account backend error clearly', () {
      final message = AuthErrorMessages.resolve(
        StateError('Internal user is not provisioned.'),
        flow: AuthFlow.internalGoogle,
      );

      expect(
        message,
        'This Google account is not provisioned for SHIELD internal access.',
      );
    });

    test('maps customer provisioning redirect error clearly', () {
      final message = AuthErrorMessages.resolve(
        StateError('Customer is not provisioned in SHIELD.'),
        flow: AuthFlow.customerOtp,
      );

      expect(
        message,
        'This mobile number is verified, but the SHIELD customer profile is not set up yet.',
      );
    });

    test('maps session expiration to a relogin message', () {
      final message = AuthErrorMessages.resolve(
        StateError('Session expired'),
        flow: AuthFlow.sessionRestore,
      );

      expect(
        message,
        'Your SHIELD session expired. Sign in again to continue securely.',
      );
    });

    test('maps Firebase security errors without falsely diagnosing a network failure', () {
      final message = AuthErrorMessages.resolve(
        FirebaseAuthException(
          code: 'captcha-check-failed',
          message: 'enterprise check failed',
        ),
        flow: AuthFlow.customerLogin,
      );

      expect(message, contains('security check'));
      expect(message, isNot(contains('Network connection lost')));
    });

    test('maps an actual Firebase connectivity error to the network message', () {
      final message = AuthErrorMessages.resolve(
        FirebaseAuthException(
          code: 'network-request-failed',
          message: 'network failure',
        ),
        flow: AuthFlow.customerLogin,
      );

      expect(message, 'Network connection lost. Check your internet connection and try again.');
    });
  });
}
