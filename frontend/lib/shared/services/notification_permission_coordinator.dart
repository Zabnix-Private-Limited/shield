import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../widgets/shield_notification_permission_dialog.dart';
import 'firebase_bootstrap_service.dart';

class NotificationPermissionCoordinator extends ChangeNotifier {
  NotificationPermissionCoordinator._();

  static final NotificationPermissionCoordinator instance =
      NotificationPermissionCoordinator._();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const _deferredKey = 'notification_prompt_deferred';

  bool _initialized = false;
  bool _isPrompting = false;
  bool _promptDeferred = false;
  AuthorizationStatus _status = AuthorizationStatus.notDetermined;

  bool get isInitialized => _initialized;
  bool get isPrompting => _isPrompting;
  bool get promptDeferred => _promptDeferred;
  AuthorizationStatus get status => _status;

  bool get isGranted =>
      _status == AuthorizationStatus.authorized ||
      _status == AuthorizationStatus.provisional;

  bool get isPermanentlyDenied => _status == AuthorizationStatus.denied;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final deferredVal = await _storage.read(key: _deferredKey);
      _promptDeferred = deferredVal == 'true';

      if (AppConfig.enableNotifications) {
        final settings =
            await FirebaseMessaging.instance.getNotificationSettings();
        _status = settings.authorizationStatus;
      }
    } catch (e) {
      debugPrint('[NotificationCoordinator] Init error: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> shouldShowPrePermissionDialog() async {
    if (!AppConfig.enableNotifications) return false;
    await initialize();

    // If already granted or explicitly deferred by user, do not show custom prompt automatically.
    if (isGranted) return false;
    if (_promptDeferred) return false;
    if (isPermanentlyDenied) return false;

    return _status == AuthorizationStatus.notDetermined;
  }

  Future<void> maybeShowPrePermissionPrompt(BuildContext context) async {
    if (!context.mounted) return;
    final shouldShow = await shouldShowPrePermissionDialog();
    if (!shouldShow || _isPrompting || !context.mounted) return;

    _isPrompting = true;
    notifyListeners();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const ShieldNotificationPermissionDialog(),
      );
    } catch (e) {
      debugPrint('[NotificationCoordinator] Dialog display error: $e');
    } finally {
      _isPrompting = false;
      notifyListeners();
    }
  }

  Future<void> requestPermissionFromUserAction() async {
    if (!AppConfig.enableNotifications) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      _status = settings.authorizationStatus;
      debugPrint(
        '[NotificationCoordinator] User granted/updated status: ${_status.name}',
      );

      if (isGranted) {
        await FirebaseBootstrapService.registerCurrentPushToken();
      }
    } catch (e) {
      debugPrint('[NotificationCoordinator] Permission request error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> deferPromptFromUserAction() async {
    _promptDeferred = true;
    try {
      await _storage.write(key: _deferredKey, value: 'true');
    } catch (e) {
      debugPrint('[NotificationCoordinator] Defer write error: $e');
    }
    notifyListeners();
  }

  Future<void> openAppNotificationSettings() async {
    try {
      if (kIsWeb) return;
      const url = 'app-settings:';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      debugPrint('[NotificationCoordinator] Settings launch error: $e');
    }
  }
}
