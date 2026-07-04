import 'package:flutter/foundation.dart';

class AdminSearchController extends ChangeNotifier {
  String _query = '';

  String get query => _query;

  void update(String value) {
    if (_query == value) {
      return;
    }
    _query = value;
    notifyListeners();
  }

  void clear() => update('');
}
