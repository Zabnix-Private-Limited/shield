import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes/app_router.dart';
import '../utils/deep_link_generator.dart';
import 'customer_auth_session.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  static DeepLinkService get instance => _instance;

  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  /// Initializes deep link listening across Android, iOS, Web, and desktop platforms.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Handle cold start deep link (app launched via deep link URL)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }

      // Listen for incoming deep links while app is running in background or foreground
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) => _handleIncomingUri(uri),
        onError: (err) {
          if (kDebugMode) {
            debugPrint('[DeepLinkService] Deep link error: $err');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeepLinkService] Failed to initialize app_links: $e');
      }
    }
  }

  void _handleIncomingUri(Uri uri) {
    if (kDebugMode) {
      debugPrint('[DeepLinkService] Incoming Deep Link: $uri');
    }

    final targetPath = DeepLinkGenerator.normalizeToRoutePath(uri);
    if (targetPath == null || targetPath.isEmpty) return;

    // Check if deep link contains referral code
    final parsedUri = Uri.parse(targetPath);
    final ref =
        parsedUri.queryParameters['ref'] ?? parsedUri.queryParameters['code'];
    if (ref != null && ref.trim().isNotEmpty) {
      CustomerAuthSession.instance.setPendingReferralCode(ref.trim());
    }

    // Delay slightly to ensure GoRouter navigator context is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          context.go(targetPath);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DeepLinkService] Navigation failed: $e');
        }
      }
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
    _initialized = false;
  }
}
