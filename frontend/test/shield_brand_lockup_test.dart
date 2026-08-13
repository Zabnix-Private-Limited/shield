import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shield/shared/widgets/shield_brand_lockup.dart';

class _FailingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key == 'AssetManifest.bin' || key == 'AssetManifest.json') {
      return rootBundle.load(key);
    }
    return Future<ByteData>.error(StateError('Missing asset: $key'));
  }
}

void main() {
  testWidgets('brand lockup remains stable when the logo asset cannot load',
      (tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _FailingAssetBundle(),
        child: const MaterialApp(home: Scaffold(body: ShieldBrandLockup())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
  });

  testWidgets('SHIELD mark resolves from the Flutter production asset key',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ShieldBrandLockup())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
