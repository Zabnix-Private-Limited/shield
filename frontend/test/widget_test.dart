import 'package:flutter_test/flutter_test.dart';
import 'package:shield/app/routes/app_router.dart';

void main() {
  test('starts on the customer splash route', () {
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/customer/splash',
    );
  });
}
