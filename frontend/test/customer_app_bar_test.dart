import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/app/theme/app_colors.dart';
import 'package:shield/features/customer/shared/widgets/customer_app_bar.dart';
import 'package:shield/features/customer/shared/widgets/customer_scaffold.dart';
import 'package:shield/features/portal/presentation/portal_role_data.dart';
import 'package:shield/shared/models/shield_role.dart';

void main() {
  testWidgets('fits the main customer header at 480 and 448 pixel widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final width in <double>[480, 448]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
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
    }
  });

  testWidgets('fits inside the customer scaffold SafeArea at 448 pixels', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(448, 800));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(448, 800),
            padding: EdgeInsets.only(top: 24),
          ),
          child: CustomerScaffold(
            portal: _portal,
            section: _dashboardSection,
            activeSectionKey: 'dashboard',
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
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
