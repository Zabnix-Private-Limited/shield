import 'package:flutter/foundation.dart';

class AdminSelectionController<T> extends ChangeNotifier {
  T? _selected;

  T? get selected => _selected;

  void select(T value) {
    if (_selected == value) {
      return;
    }
    _selected = value;
    notifyListeners();
  }

  void clear() {
    if (_selected == null) {
      return;
    }
    _selected = null;
    notifyListeners();
  }
}
