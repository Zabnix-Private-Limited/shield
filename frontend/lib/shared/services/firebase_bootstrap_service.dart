import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'customer_auth_session.dart';

@pragma('vm:entry-point')
Future<void> shieldFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('SHIELD background push received: ${message.messageId}');
}

class FirebaseBootstrapService {
  FirebaseBootstrapService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.initializeRecaptchaConfig();
      } catch (error) {
        debugPrint('SHIELD web reCAPTCHA config warmup skipped: $error');
      }
    }

    if (AppConfig.enableNotifications) {
      FirebaseMessaging.onBackgroundMessage(
        shieldFirebaseMessagingBackgroundHandler,
      );
      await _initializeMessaging();
    }

    await _initializeAnalytics();

    _initialized = true;
  }

  static Future<void> _initializeAnalytics() async {
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    } catch (error) {
      debugPrint('SHIELD analytics unavailable: $error');
    }
  }

  static Future<void> _registerPushTokenSafely(String token) async {
    final customerId = CustomerAuthSession.instance.customerId?.trim();
    if (!CustomerAuthSession.instance.isAuthenticated ||
        customerId == null ||
        customerId.isEmpty) {
      debugPrint(
        'SHIELD push token registration skipped until customer auth is active.',
      );
      return;
    }

    try {
      await ApiService.registerPushToken(
        token: token,
        platform: ApiService.resolvePushPlatform(),
        customerId: customerId,
      );
    } on DioException catch (error) {
      debugPrint(
        'SHIELD push token registration skipped because backend is unavailable: ${error.message}',
      );
    } catch (error) {
      debugPrint('SHIELD push token registration failed: $error');
    }
  }

  static Future<void> registerCurrentPushToken() async {
    if (!AppConfig.enableNotifications) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final token = kIsWeb
          ? await messaging.getToken(vapidKey: AppConfig.firebaseWebVapidKey)
          : await messaging.getToken();

      debugPrint('SHIELD device push token: $token');

      if (token != null && token.trim().isNotEmpty) {
        await _registerPushTokenSafely(token);
      }
    } catch (error) {
      debugPrint('SHIELD current push token lookup failed: $error');
    }
  }

  static Future<void> _initializeMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        'SHIELD push permission status: ${settings.authorizationStatus.name}',
      );

      if (kIsWeb && AppConfig.firebaseWebVapidKey.isEmpty) {
        debugPrint(
          'SHIELD web push token skipped because FIREBASE_WEB_VAPID_KEY is empty.',
        );
      } else {
        await registerCurrentPushToken();
      }

      messaging.onTokenRefresh.listen((token) async {
        debugPrint('SHIELD push token refreshed: $token');
        await _registerPushTokenSafely(token);
      });

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          'SHIELD foreground push received: ${message.messageId} ${message.notification?.title ?? ''}',
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint(
          'SHIELD push opened app: ${message.messageId} ${message.notification?.title ?? ''}',
        );
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'SHIELD app launched from push: ${initialMessage.messageId}',
        );
      }
    } catch (error) {
      debugPrint('SHIELD push bootstrap failed: $error');
    }
  }
}
