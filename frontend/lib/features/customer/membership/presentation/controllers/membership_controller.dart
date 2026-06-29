import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/membership_model.dart';
import '../../data/repositories/membership_repository.dart';

class MembershipController extends ChangeNotifier {
  MembershipController({
    MembershipRepository? repository,
    this.customerId = '1',
  }) : _repository = repository ?? MembershipRepository();

  final MembershipRepository _repository;
  final String customerId;

  bool _isLoading = false;
  bool _isRefreshing = false;
  Object? _error;
  MembershipModel? _membership;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  Object? get error => _error;
  MembershipModel? get membership => _membership;
  bool get hasData => _membership != null;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cached = await _repository.loadCachedMembership();
    if (cached != null) {
      _membership = cached;
      _isLoading = false;
      notifyListeners();
      unawaited(_refreshInBackground());
      return;
    }

    try {
      _membership = await _repository.loadMembership(customerId);
    } catch (err) {
      _error = err;
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
      _membership = await _repository.refreshMembership(customerId);
    } catch (err) {
      _error = err;
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
      _membership = await _repository.refreshMembership(customerId);
    } catch (err) {
      _error ??= err;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
