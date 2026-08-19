import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/provider/pharmacy/presentation/screens/pharmacy_profile_screen.dart';
import 'package:shield/features/provider/pharmacy/presentation/screens/pharmacy_settings_screen.dart';
import 'package:shield/features/provider/pharmacy/presentation/widgets/pharmacy_skeletons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final viewports = [
    const Size(390, 844),   // iPhone 12/13/14 Pro
    const Size(412, 915),   // Pixel 7
    const Size(912, 1368),  // Surface Pro 7
    const Size(1024, 768),  // iPad / Desktop mini
    const Size(1366, 768),  // Standard Laptop
    const Size(1440, 900),  // Desktop
  ];

  group('PharmacyProfileScreen Responsive Render Tests', () {
    for (final size in viewports) {
      testWidgets('Renders cleanly without overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PharmacyProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Pharmacy Profile'), findsOneWidget);
      });
    }
  });

  group('PharmacySettingsScreen Responsive Render Tests', () {
    for (final size in viewports) {
      testWidgets('Renders cleanly without overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PharmacySettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Pharmacy Settings'), findsOneWidget);
      });
    }
  });

  group('Pharmacy Skeletons Responsive Render Tests', () {
    testWidgets('PharmacyProfileSkeleton renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PharmacyProfileSkeleton()),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PharmacyProfileSkeleton), findsOneWidget);
    });

    testWidgets('PharmacySettingsSkeleton renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PharmacySettingsSkeleton()),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PharmacySettingsSkeleton), findsOneWidget);
    });
  });
}
