import '../datasources/customer_provider_remote.dart';
import '../models/customer_provider.dart';

class CustomerProviderRepository {
  CustomerProviderRepository({CustomerProviderRemoteDataSource? remote})
    : _remote = remote ?? CustomerProviderRemoteDataSource();

  final CustomerProviderRemoteDataSource _remote;
  static const _cacheTtl = Duration(minutes: 2);
  static _CachedValue<List<CustomerProviderCategory>>? _categoriesCache;
  static Future<List<CustomerProviderCategory>>? _categoriesInFlight;
  static final Map<String, _CachedValue<CustomerProviderPage>> _pageCache = {};
  static final Map<String, Future<CustomerProviderPage>> _pagesInFlight = {};
  static final Map<String, _CachedValue<CustomerProvider>> _providerCache = {};
  static final Map<String, Future<CustomerProvider>> _providersInFlight = {};

  Future<List<CustomerProviderCategory>> categories({
    bool forceRefresh = false,
  }) async {
    final cached = _categoriesCache;
    if (!forceRefresh && cached != null && cached.isFresh) return cached.value;
    final existing = _categoriesInFlight;
    if (existing != null) return existing;
    final request = _remote.categories();
    _categoriesInFlight = request;
    try {
      final categories = await request;
      _categoriesCache = _CachedValue(categories);
      return categories;
    } finally {
      if (identical(_categoriesInFlight, request)) _categoriesInFlight = null;
    }
  }

  Future<CustomerProviderPage> providers({
    String? query,
    String? type,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final key = '${query?.trim() ?? ''}|${type?.trim() ?? ''}|$page';
    final cached = _pageCache[key];
    if (!forceRefresh && cached != null && cached.isFresh) return cached.value;
    final existing = _pagesInFlight[key];
    if (existing != null) return existing;
    final request = _remote.providers(query: query, type: type, page: page);
    _pagesInFlight[key] = request;
    try {
      final result = await request;
      _pageCache[key] = _CachedValue(result);
      return result;
    } finally {
      if (identical(_pagesInFlight[key], request)) _pagesInFlight.remove(key);
    }
  }

  Future<CustomerProvider> provider(
    String id, {
    bool forceRefresh = false,
  }) async {
    final key = id.trim();
    final cached = _providerCache[key];
    if (!forceRefresh && cached != null && cached.isFresh) return cached.value;
    final existing = _providersInFlight[key];
    if (existing != null) return existing;
    final request = _remote.provider(key);
    _providersInFlight[key] = request;
    try {
      final provider = await request;
      _providerCache[key] = _CachedValue(provider);
      return provider;
    } finally {
      if (identical(_providersInFlight[key], request)) {
        _providersInFlight.remove(key);
      }
    }
  }
}

class _CachedValue<T> {
  _CachedValue(this.value) : cachedAt = DateTime.now();

  final T value;
  final DateTime cachedAt;

  bool get isFresh =>
      DateTime.now().difference(cachedAt) <
      CustomerProviderRepository._cacheTtl;
}
