import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/features/customer/shared/widgets/customer_app_bar.dart';
import 'package:shield/features/portal/presentation/portal_role_data.dart';
import 'package:shield/shared/models/shield_role.dart';

void main() {
  testWidgets('fits the main customer header in the reported narrow viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(76),
            child: CustomerAppBar(
              portal: _portal,
              section: _dashboardSection,
              onMenuPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
    expect(find.byTooltip('Retry account summary'), findsOneWidget);
  });
}

const _dashboardSection = PortalSectionData(
  key: 'dashboard',
  title: 'Dashboard',
  summary: 'Customer overview',
  actions: <String>[],
  metrics: <PortalMetric>[],
  queueItems: <PortalListItem>[],
  recentItems: <PortalListItem>[],
  insightItems: <PortalListItem>[],
);

const _portal = PortalRoleData(
  role: SHIELDRole.customer,
  operatorName: 'Customer',
  headline: 'Dashboard',
  regionLabel: 'SHIELD',
  icon: Icons.shield_outlined,
  accentColor: AppColors.shieldBlue,
  sections: <PortalSectionData>[_dashboardSection],
);
