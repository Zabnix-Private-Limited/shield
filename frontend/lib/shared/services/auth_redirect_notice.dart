import 'package:flutter/foundation.dart';

import 'active_auth_session.dart';

class AuthRedirectNotice extends ChangeNotifier {
  AuthRedirectNotice._();

  static final AuthRedirectNotice instance = AuthRedirectNotice._();

  ShieldSessionKind? _sessionKind;
  String? _message;

  ShieldSessionKind? get sessionKind => _sessionKind;
  String? get message => _message;
  bool get hasNotice =>
      _sessionKind != null && _message != null && _message!.trim().isNotEmpty;

  String get targetRoute {
    return _sessionKind == ShieldSessionKind.internal
        ? '/internal/login'
        : '/customer/login';
  }

  void showSessionExpired({
    required ShieldSessionKind sessionKind,
    required String message,
  }) {
    _sessionKind = sessionKind;
    _message = message.trim();
    notifyListeners();
  }

  void clear() {
    if (_sessionKind == null && (_message == null || _message!.isEmpty)) {
      return;
    }
    _sessionKind = null;
    _message = null;
    notifyListeners();
  }
}
