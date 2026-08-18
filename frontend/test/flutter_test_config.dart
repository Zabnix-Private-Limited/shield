import 'dart:async';
// PRODUCTION CODE (UNCOMMENT WHEN GOLDEN TOOLKIT IS ACTIVATED):
// import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // await loadAppFonts();
  await testMain();
}
