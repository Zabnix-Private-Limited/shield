enum CustomerPhoneVerificationState {
  idle,
  sending,
  codeSent,
  verifying,
  verified,
  resending,
  firebaseFailure,
  connectivityFailure,
}

/// Presentation-independent OTP state. Keeping this small model separate from
/// Firebase lets the UI distinguish a confirmed send from a later failure.
class CustomerPhoneVerificationStateMachine<T> {
  CustomerPhoneVerificationState _state =
      CustomerPhoneVerificationState.idle;
  T? _confirmation;
  bool _requestInFlight = false;
  String? _errorMessage;

  CustomerPhoneVerificationState get state => _state;
  T? get confirmation => _confirmation;
  String? get errorMessage => _errorMessage;
  bool get requestInFlight => _requestInFlight;

  bool beginSend({required bool resend}) {
    if (_requestInFlight) return false;
    _requestInFlight = true;
    _errorMessage = null;
    _state = resend
        ? CustomerPhoneVerificationState.resending
        : CustomerPhoneVerificationState.sending;
    return true;
  }

  void sendSucceeded(T confirmation) {
    _confirmation = confirmation;
    _errorMessage = null;
    _requestInFlight = false;
    _state = CustomerPhoneVerificationState.codeSent;
  }

  void sendFailed(Object error) {
    _requestInFlight = false;
    _errorMessage = error.toString();
    _state = isCustomerConnectivityFailure(error)
        ? CustomerPhoneVerificationState.connectivityFailure
        : CustomerPhoneVerificationState.firebaseFailure;
  }

  void beginVerification() {
    _errorMessage = null;
    _state = CustomerPhoneVerificationState.verifying;
  }

  void verified() {
    _errorMessage = null;
    _state = CustomerPhoneVerificationState.verified;
  }

  void reset() {
    _state = CustomerPhoneVerificationState.idle;
    _confirmation = null;
    _errorMessage = null;
    _requestInFlight = false;
  }
}

bool isCustomerConnectivityFailure(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('network-request-failed') ||
      message.contains('network') ||
      message.contains('socket') ||
      message.contains('connection refused') ||
      message.contains('connection timed out');
}
