import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/portal/presentation/portal_role_data.dart';
import 'package:shield/shared/models/shield_role.dart';

void main() {
  test('keeps book appointment and removes unsupported recharge', () {
    final sections = portalDataForRole(SHIELDRole.customer).sections;
    final keys = sections.map((section) => section.key);

    expect(keys, contains('book-appointment'));
    expect(keys, contains('account'));
    expect(keys, isNot(contains('recharge')));
  });
}
