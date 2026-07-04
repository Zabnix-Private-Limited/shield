import 'package:flutter/foundation.dart';

class AdminNavigationController extends ChangeNotifier {
  String _activeSection = 'dashboard';

  String get activeSection => _activeSection;

  void setActiveSection(String key) {
    if (_activeSection == key) {
      return;
    }
    _activeSection = key;
    notifyListeners();
  }
}
