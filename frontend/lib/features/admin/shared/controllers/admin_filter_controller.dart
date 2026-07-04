import 'package:flutter/foundation.dart';

class AdminFilterController extends ChangeNotifier {
  final Map<String, String> _filters = <String, String>{};

  Map<String, String> get filters => Map<String, String>.unmodifiable(_filters);

  void setFilter(String key, String value) {
    _filters[key] = value;
    notifyListeners();
  }

  void clear() {
    if (_filters.isEmpty) {
      return;
    }
    _filters.clear();
    notifyListeners();
  }
}
