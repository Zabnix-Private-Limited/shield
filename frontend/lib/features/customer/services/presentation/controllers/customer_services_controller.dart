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

  Future<void> load({String? query, String? type}) async {
    this.query = query?.trim() ?? this.query;
    selectedType = type ?? selectedType;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _repository.categories(),
        _repository.providers(query: this.query, type: selectedType),
      ]);
      categories = values[0] as List<CustomerProviderCategory>;
      page = values[1] as CustomerProviderPage;
    } catch (value) {
      error = value;
    } finally {
      isLoading = false;
      notifyListeners();
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
      page = CustomerProviderPage(
        items: [...page.items, ...next.items],
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
