import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'customer_auth_session.dart';
import 'device_identity_service.dart';
import 'notification_navigation_service.dart';

@pragma('vm:entry-point')
Future<void> shieldFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('SHIELD background push received: ${message.messageId}');
}

class FirebaseBootstrapService {
  FirebaseBootstrapService._();

  static bool _coreInitialized = false;
  static bool _backgroundServicesInitialized = false;

  /// Initializes only the Firebase core required by authentication.
  ///
  /// Messaging permission, token lookup, and analytics are deliberately
  /// deferred until after SHIELD has rendered its first application frame.
  static Future<void> initializeCore() async {
    if (_coreInitialized) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _coreInitialized = true;
  }

  /// Starts non-critical Firebase services without holding up app startup.
  static Future<void> initializeBackgroundServices() async {
    await initializeCore();
    if (_backgroundServicesInitialized) {
      return;
    }

    _backgroundServicesInitialized = true;

    if (AppConfig.enableNotifications) {
      FirebaseMessaging.onBackgroundMessage(
        shieldFirebaseMessagingBackgroundHandler,
      );
      await _initializeMessaging();
    }

    await _initializeAnalytics();
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
        deviceId: await DeviceIdentityService.getInstallationId(),
        deviceLabel: DeviceIdentityService.defaultDeviceLabel(),
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

      debugPrint(
        token == null || token.trim().isEmpty
            ? 'SHIELD device push token unavailable.'
            : 'SHIELD device push token acquired.',
      );

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

      final settings = await messaging.getNotificationSettings();
      debugPrint(
        'SHIELD push permission status: ${settings.authorizationStatus.name}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kIsWeb && AppConfig.firebaseWebVapidKey.isEmpty) {
          debugPrint(
            'SHIELD web push token skipped because FIREBASE_WEB_VAPID_KEY is empty.',
          );
        } else {
          await registerCurrentPushToken();
        }
      }

      messaging.onTokenRefresh.listen((token) async {
        debugPrint('SHIELD push token refreshed.');
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
        NotificationNavigationService.handleCustomerPush(message.data);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'SHIELD app launched from push: ${initialMessage.messageId}',
        );
        NotificationNavigationService.handleCustomerPush(initialMessage.data);
      }
    } catch (error) {
      debugPrint('SHIELD push bootstrap failed: $error');
    }
  }
}
