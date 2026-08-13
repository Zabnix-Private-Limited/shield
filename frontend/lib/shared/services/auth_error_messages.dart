import 'package:firebase_auth/firebase_auth.dart';

enum AuthFlow {
  customerLogin,
  customerOtp,
  customerRegistration,
  internalGoogle,
  sessionRestore,
}

class AuthErrorMessages {
  const AuthErrorMessages._();

  static String resolve(Object error, {required AuthFlow flow}) {
    if (error is FirebaseAuthException) {
      final code = error.code.trim().toLowerCase();
      switch (code) {
        case 'invalid-verification-code':
          return 'The OTP you entered is invalid. Check the 6-digit code and try again.';
        case 'session-expired':
        case 'code-expired':
          return 'This OTP has expired. Request a new code and try again.';
        case 'invalid-phone-number':
          return 'Enter a valid mobile number to continue.';
        case 'too-many-requests':
          return 'Too many attempts were made just now. Please wait a moment and try again.';
        case 'quota-exceeded':
          return 'SMS verification is temporarily unavailable due to request limits. Please try again later.';
        case 'captcha-check-failed':
        case 'invalid-app-credential':
        case 'missing-app-credential':
          return 'SHIELD could not complete the security check. Refresh the page and try again.';
        case 'web-phone-auth-domain':
          return 'This SHIELD web address is not configured for phone verification. Please use the official SHIELD site.';
        case 'network-request-failed':
          return 'Network connection lost. Check your internet connection and try again.';
        case 'popup-closed-by-user':
        case 'popup-blocked':
        case 'cancelled-popup-request':
        case 'sign_in_canceled':
        case 'sign-in-cancelled':
          return flow == AuthFlow.internalGoogle
              ? 'Google sign-in was cancelled before SHIELD access could be completed.'
              : 'The sign-in flow was cancelled before SHIELD could finish verification.';
        case 'account-exists-with-different-credential':
          return 'This Google account is linked differently in Firebase. Use the approved sign-in method for this account.';
        case 'web-context-cancelled':
          return 'The browser interrupted the sign-in flow. Re-open SHIELD and try again.';
        default:
          return 'SHIELD could not complete Firebase verification right now. Please try again.';
      }
    }

    final message = _clean(error.toString());
    final lowered = message.toLowerCase();

    if (lowered.contains('not provisioned')) {
      switch (flow) {
        case AuthFlow.customerOtp:
        case AuthFlow.customerRegistration:
          return 'This mobile number is verified, but the SHIELD customer profile is not set up yet.';
        case AuthFlow.internalGoogle:
          return 'This Google account is not provisioned for SHIELD internal access.';
        case AuthFlow.customerLogin:
        case AuthFlow.sessionRestore:
          return message;
      }
    }

    if (lowered.contains('status suspended') ||
        lowered.contains('status inactive') ||
        lowered.contains('status deleted')) {
      return 'This SHIELD account is currently inactive. Contact support or your administrator for access help.';
    }

    if (lowered.contains('assigned shield role')) {
      return 'This internal account is missing a SHIELD role assignment. Ask an administrator to finish access setup.';
    }

    if (lowered.contains('session expired') ||
        lowered.contains('expired or is no longer valid') ||
        lowered.contains('invalid or expired shield access token') ||
        lowered.contains('refresh token is invalid or expired')) {
      return 'Your SHIELD session expired. Sign in again to continue securely.';
    }

    if (lowered.contains('session store is temporarily unavailable')) {
      return 'SHIELD authentication is temporarily unavailable. Please try again shortly.';
    }

    if (lowered.contains('permission') && lowered.contains('denied')) {
      return 'Your account signed in successfully, but SHIELD denied access to this action.';
    }

    if (lowered.contains('network') || lowered.contains('socket')) {
      return 'Network connection lost. Check your internet connection and try again.';
    }

    if (message.isNotEmpty &&
        !message.startsWith('Exception') &&
        !message.startsWith('StateError')) {
      return message;
    }

    switch (flow) {
      case AuthFlow.customerLogin:
        return 'Unable to start SHIELD OTP login right now. Please try again.';
      case AuthFlow.customerOtp:
        return 'SHIELD could not complete OTP verification right now. Please try again.';
      case AuthFlow.customerRegistration:
        return 'SHIELD could not finish customer registration right now. Please try again.';
      case AuthFlow.internalGoogle:
        return 'SHIELD could not complete Google sign-in right now. Please try again.';
      case AuthFlow.sessionRestore:
        return 'SHIELD could not restore your session right now. Please sign in again.';
    }
  }

  static String _clean(String input) {
    return input
        .trim()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '');
  }
}
