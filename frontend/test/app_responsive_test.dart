import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/widgets/app_responsive.dart';

void main() {
  test('customer portal viewport width stays phone-sized on large screens', () {
    expect(AppResponsive.customerViewportWidth(390), 390);
    expect(AppResponsive.customerViewportWidth(768), 480);
    expect(AppResponsive.customerViewportWidth(1440), 480);
  });
}
