import 'package:flutter_test/flutter_test.dart';
import 'package:shield/app/routes/app_router.dart';

void main() {
  test('starts on the customer portal dashboard route', () {
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/portal/customer/dashboard',
    );
  });
}
