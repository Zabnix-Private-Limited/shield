import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdentityService {
  DeviceIdentityService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const _installationIdKey = 'shield_device_installation_id';

  static Future<String> getInstallationId() async {
    final existing = await _storage.read(key: _installationIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final generated = _generateInstallationId();
    await _storage.write(key: _installationIdKey, value: generated);
    return generated;
  }

  static String resolvePlatform() {
    if (kIsWeb) {
      return 'WEB';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.windows:
        return 'WINDOWS';
      case TargetPlatform.macOS:
        return 'MACOS';
      case TargetPlatform.linux:
        return 'LINUX';
      case TargetPlatform.fuchsia:
        return 'FUCHSIA';
    }
  }

  static String defaultDeviceLabel() {
    switch (resolvePlatform()) {
      case 'ANDROID':
        return 'Android Device';
      case 'IOS':
        return 'iPhone / iPad';
      case 'WINDOWS':
        return 'Windows Device';
      case 'MACOS':
        return 'Mac Device';
      case 'LINUX':
        return 'Linux Device';
      case 'WEB':
        return 'Web Browser';
      case 'FUCHSIA':
        return 'Fuchsia Device';
    }

    return 'SHIELD Device';
  }

  static String _generateInstallationId() {
    final random = Random.secure();
    final seed = List.generate(
      4,
      (_) => random.nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0'),
    ).join();
    return '${DateTime.now().microsecondsSinceEpoch}-$seed';
  }
}
