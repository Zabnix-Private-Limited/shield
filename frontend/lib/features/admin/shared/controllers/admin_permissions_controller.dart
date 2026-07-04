import 'package:flutter/foundation.dart';

class AdminPermissionsController extends ChangeNotifier {
  final Set<String> _permissions = <String>{};

  Set<String> get permissions => Set<String>.unmodifiable(_permissions);

  void hydrate(Iterable<String> values) {
    _permissions
      ..clear()
      ..addAll(values);
    notifyListeners();
  }

  bool can(String permission) => _permissions.contains(permission);
}
