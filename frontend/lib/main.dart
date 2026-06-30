import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'app/theme/app_theme.dart';
import 'app/routes/app_router.dart';
import 'shared/config/app_config.dart';
import 'shared/services/customer_auth_session.dart';
import 'shared/services/firebase_auth_web_registration.dart';
import 'shared/services/firebase_bootstrap_service.dart';
import 'shared/services/internal_auth_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureFirebaseAuthWebRegistration();
  await Hive.initFlutter();
  await CustomerAuthSession.instance.initialize();
  await InternalAuthSession.instance.initialize();
  await FirebaseBootstrapService.initialize();

  if (AppConfig.enableSentry &&
      !kIsWeb &&
      AppConfig.sentryFlutterDsn.trim().isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        const isProduction = bool.fromEnvironment('dart.vm.product');
        options.dsn = AppConfig.sentryFlutterDsn.trim();
        options.environment = AppConfig.sentryEnvironment.trim();
        options.release = AppConfig.sentryRelease.trim();
        options.sendDefaultPii = true;
        options.tracesSampleRate = isProduction ? 0.2 : 1.0;
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;
      },
      appRunner: () =>
          runApp(SentryWidget(child: const ProviderScope(child: MyApp()))),
    );
    return;
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SHIELD',
      debugShowCheckedModeBanner: false,
      builder: FToastBuilder(),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
        overscroll: false,
      ),
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
