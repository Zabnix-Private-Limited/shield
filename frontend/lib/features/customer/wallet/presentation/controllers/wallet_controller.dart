import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallet_repository.dart';

class WalletController extends ChangeNotifier {
  WalletController({
    WalletRepository? repository,
    this.customerId = '1',
  }) : _repository = repository ?? WalletRepository();

  final WalletRepository _repository;
  final String customerId;

  bool _isLoading = false;
  bool _isRefreshing = false;
  Object? _error;
  WalletModel? _wallet;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  Object? get error => _error;
  WalletModel? get wallet => _wallet;
  bool get hasData => _wallet != null;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cached = await _repository.loadCachedWallet();
    if (cached != null) {
      _wallet = cached;
      _isLoading = false;
      notifyListeners();
      unawaited(_refreshInBackground());
      return;
    }

    try {
      _wallet = await _repository.loadWallet(customerId);
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      _wallet = await _repository.refreshWallet(customerId);
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> invalidateCache() {
    return _repository.invalidateCache();
  }

  Future<void> _refreshInBackground() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      _wallet = await _repository.refreshWallet(customerId);
    } catch (error) {
      _error ??= error;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
