import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/provider/settings/presentation/screens/provider_settings_screen.dart';
import 'package:shield/features/provider/shared/presentation/widgets/provider_workspace_scaffold.dart';
import 'package:shield/shared/widgets/app_page_frame.dart';
import 'package:shield/shared/widgets/app_skeleton.dart';

void main() {
  const viewports = <String, Size>{
    'Phone 360x800': Size(360, 800),
    'Large Phone 390x844': Size(390, 844),
    'Tablet 768x1024': Size(768, 1024),
    'Desktop 1440x900': Size(1440, 900),
  };

  Widget buildSliverTestHost(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppPageFrame(
                  maxWidth: 1240,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('Shared Embedded Skeleton Unbounded Height Regression Tests', () {
    for (final entry in viewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets(
        'AppPortalSectionSkeleton renders cleanly inside SliverToBoxAdapter on $name',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            buildSliverTestHost(const AppPortalSectionSkeleton()),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(AppPortalSectionSkeleton), findsOneWidget);
        },
      );

      testWidgets(
        'AppPageSkeleton(showSidebar: false) renders cleanly inside SliverToBoxAdapter on $name',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            buildSliverTestHost(const AppPageSkeleton(showSidebar: false)),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(AppPageSkeleton), findsOneWidget);
        },
      );

      testWidgets(
        'AppCustomerSectionSkeleton renders cleanly inside SliverToBoxAdapter on $name',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            buildSliverTestHost(const AppCustomerSectionSkeleton()),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(AppCustomerSectionSkeleton), findsOneWidget);
        },
      );
    }
  });

  group('Provider Settings Workspace Layout Regression Tests', () {
    for (final entry in viewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets(
        'ProviderSettingsScreen renders loading & loaded states without layout crash on $name',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            buildSliverTestHost(const ProviderSettingsScreen()),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);

          await tester.pump(const Duration(milliseconds: 500));

          expect(tester.takeException(), isNull);
          expect(find.byType(ProviderSettingsScreen), findsOneWidget);
        },
      );

      testWidgets(
        'ProviderWorkspaceScaffold renders cleanly in loading state on $name',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            buildSliverTestHost(
              ProviderWorkspaceScaffold(
                builder: (context, ref, controller) => const Text('Workspace Loaded'),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
