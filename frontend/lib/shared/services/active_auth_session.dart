import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum ShieldSessionKind { customer, internal }

class ActiveAuthSession {
  ActiveAuthSession._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _activeKindKey = 'shield_active_session_kind';

  static Future<ShieldSessionKind?> getActiveKind() async {
    final value = await _storage.read(key: _activeKindKey);
    switch (value?.trim()) {
      case 'customer':
        return ShieldSessionKind.customer;
      case 'internal':
        return ShieldSessionKind.internal;
      default:
        return null;
    }
  }

  static Future<void> setActiveKind(ShieldSessionKind kind) {
    return _storage.write(
      key: _activeKindKey,
      value: kind == ShieldSessionKind.customer ? 'customer' : 'internal',
    );
  }

  static Future<void> clearActiveKind() {
    return _storage.delete(key: _activeKindKey);
  }
}
