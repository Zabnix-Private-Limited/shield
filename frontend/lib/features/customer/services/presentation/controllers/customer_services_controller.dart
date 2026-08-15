import 'package:flutter/foundation.dart';

import '../../data/models/customer_provider.dart';
import '../../data/repositories/customer_provider_repository.dart';

class CustomerServicesController extends ChangeNotifier {
  CustomerServicesController({CustomerProviderRepository? repository})
    : _repository = repository ?? CustomerProviderRepository();

  final CustomerProviderRepository _repository;
  bool isLoading = false;
  Object? error;
  List<CustomerProviderCategory> categories = const [];
  CustomerProviderPage page = const CustomerProviderPage(
    items: [],
    page: 1,
    totalPages: 1,
  );
  String? selectedType;
  String query = '';
  int _requestVersion = 0;

  Future<void> load({String? query, String? type}) async {
    this.query = query?.trim() ?? this.query;
    selectedType = type ?? selectedType;
    final requestVersion = ++_requestVersion;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _repository.categories(),
        _repository.providers(query: this.query, type: selectedType),
      ]);
      if (requestVersion != _requestVersion) return;
      categories = values[0] as List<CustomerProviderCategory>;
      page = values[1] as CustomerProviderPage;
    } catch (value) {
      if (requestVersion == _requestVersion) error = value;
    } finally {
      if (requestVersion == _requestVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> applyFilters({String? query, String? type}) async {
    this.query = query?.trim() ?? '';
    selectedType = type;
    await load();
  }

  Future<void> refresh() async {
    final requestVersion = ++_requestVersion;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _repository.categories(forceRefresh: true),
        _repository.providers(
          query: query,
          type: selectedType,
          forceRefresh: true,
        ),
      ]);
      if (requestVersion != _requestVersion) return;
      categories = values[0] as List<CustomerProviderCategory>;
      page = values[1] as CustomerProviderPage;
    } catch (value) {
      if (requestVersion == _requestVersion) error = value;
    } finally {
      if (requestVersion == _requestVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Rebuilds the visible list for a route that recorded its loaded page.
  /// The directory API is page-based, so pages are read in order to avoid a
  /// direct URL displaying only the final page of an earlier "load more" list.
  Future<void> restore({
    required String query,
    required String? type,
    int loadedPage = 1,
  }) async {
    this.query = query.trim();
    selectedType = type;
    final requestVersion = ++_requestVersion;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final restoredPages = <CustomerProvider>[];
      final categoriesFuture = _repository.categories();
      CustomerProviderPage current = const CustomerProviderPage(
        items: [],
        page: 1,
        totalPages: 1,
      );
      for (var pageNumber = 1; pageNumber <= loadedPage; pageNumber++) {
        current = await _repository.providers(
          query: this.query,
          type: selectedType,
          page: pageNumber,
        );
        restoredPages.addAll(current.items);
        if (pageNumber >= current.totalPages) break;
      }
      final unique = <String, CustomerProvider>{
        for (final provider in restoredPages) provider.id: provider,
      };
      if (requestVersion != _requestVersion) return;
      categories = await categoriesFuture;
      page = CustomerProviderPage(
        items: unique.values.toList(),
        page: current.page,
        totalPages: current.totalPages,
      );
    } catch (value) {
      if (requestVersion == _requestVersion) error = value;
    } finally {
      if (requestVersion == _requestVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadNextPage() async {
    if (isLoading || page.page >= page.totalPages) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final next = await _repository.providers(
        query: query,
        type: selectedType,
        page: page.page + 1,
      );
      final unique = <String, CustomerProvider>{
        for (final provider in [...page.items, ...next.items])
          provider.id: provider,
      };
      page = CustomerProviderPage(
        items: unique.values.toList(),
        page: next.page,
        totalPages: next.totalPages,
      );
    } catch (value) {
      error = value;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<CustomerProvider> provider(String id) => _repository.provider(id);
}
