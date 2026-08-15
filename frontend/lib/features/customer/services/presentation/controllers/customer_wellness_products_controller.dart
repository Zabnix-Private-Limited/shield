import 'package:flutter/foundation.dart';

import '../../data/models/customer_wellness_product.dart';
import '../../data/repositories/customer_wellness_product_repository.dart';

class CustomerWellnessProductsController extends ChangeNotifier {
  CustomerWellnessProductsController({
    CustomerWellnessProductRepository? repository,
  }) : _repository = repository ?? CustomerWellnessProductRepository();

  final CustomerWellnessProductRepository _repository;
  bool isLoading = false;
  Object? error;
  String query = '';
  String? selectedCategoryId;
  CustomerWellnessProductPage page = const CustomerWellnessProductPage(
    items: [],
    categories: [],
    page: 1,
    totalPages: 1,
  );
  int _requestVersion = 0;

  Future<void> load({String? query, String? categoryId}) async {
    this.query = query?.trim() ?? this.query;
    selectedCategoryId = categoryId ?? selectedCategoryId;
    final requestVersion = ++_requestVersion;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _repository.products(
        query: this.query,
        categoryId: selectedCategoryId,
      );
      if (requestVersion != _requestVersion) return;
      page = result;
    } catch (value) {
      if (requestVersion == _requestVersion) error = value;
    } finally {
      if (requestVersion == _requestVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> applyFilters({String? query, String? categoryId}) async {
    this.query = query?.trim() ?? '';
    selectedCategoryId = categoryId;
    await load();
  }

  Future<void> loadNextPage() async {
    if (isLoading || page.page >= page.totalPages) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final next = await _repository.products(
        query: query,
        categoryId: selectedCategoryId,
        page: page.page + 1,
      );
      final unique = <String, CustomerWellnessProduct>{
        for (final item in [...page.items, ...next.items]) item.id: item,
      };
      page = CustomerWellnessProductPage(
        items: unique.values.toList(),
        categories: next.categories,
        page: next.page,
        totalPages: next.totalPages,
        disclosure: next.disclosure ?? page.disclosure,
      );
    } catch (value) {
      error = value;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
