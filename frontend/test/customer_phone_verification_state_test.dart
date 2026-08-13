import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/auth/data/customer_phone_verification_state.dart';

void main() {
  test('identifies only real connectivity failures as network failures', () {
    expect(isCustomerConnectivityFailure(Exception('socket closed')), isTrue);
    expect(
      isCustomerConnectivityFailure(Exception('captcha-check-failed')),
      isFalse,
    );
  });

  test('successful send clears an old connectivity failure', () {
    final state = CustomerPhoneVerificationStateMachine<Object>();
    state.beginSend(resend: false);
    state.sendFailed(Exception('socket closed'));

    expect(state.state, CustomerPhoneVerificationState.connectivityFailure);
    expect(state.beginSend(resend: false), isTrue);
    state.sendSucceeded(Object());

    expect(state.state, CustomerPhoneVerificationState.codeSent);
    expect(state.errorMessage, isNull);
  });

  test('successful resend clears an old error and replaces confirmation', () {
    final first = Object();
    final replacement = Object();
    final state = CustomerPhoneVerificationStateMachine<Object>();
    state.beginSend(resend: false);
    state.sendSucceeded(first);
    state.beginSend(resend: true);
    state.sendFailed(Exception('captcha-check-failed'));

    expect(state.confirmation, same(first));
    expect(state.beginSend(resend: true), isTrue);
    state.sendSucceeded(replacement);

    expect(state.confirmation, same(replacement));
    expect(state.errorMessage, isNull);
    expect(state.state, CustomerPhoneVerificationState.codeSent);
  });

  test('simultaneous requests are prevented while one send is active', () {
    final state = CustomerPhoneVerificationStateMachine<Object>();

    expect(state.beginSend(resend: false), isTrue);
    expect(state.beginSend(resend: true), isFalse);
    state.sendSucceeded(Object());
    expect(state.requestInFlight, isFalse);
  });

  test('verification and Firebase failures retain distinct UI states', () {
    final state = CustomerPhoneVerificationStateMachine<Object>();
    state.beginVerification();
    expect(state.state, CustomerPhoneVerificationState.verifying);
    state.sendFailed(Exception('captcha-check-failed'));
    expect(state.state, CustomerPhoneVerificationState.firebaseFailure);
  });
}
