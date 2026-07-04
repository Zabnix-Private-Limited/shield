import 'package:flutter/foundation.dart';

class AdminWorkspaceController extends ChangeNotifier {
  bool _isBusy = false;
  String? _error;

  bool get isBusy => _isBusy;
  String? get error => _error;

  void setBusy(bool value) {
    if (_isBusy == value) {
      return;
    }
    _isBusy = value;
    notifyListeners();
  }

  void setError(String? value) {
    if (_error == value) {
      return;
    }
    _error = value;
    notifyListeners();
  }
}
