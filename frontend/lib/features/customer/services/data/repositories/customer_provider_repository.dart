import '../datasources/customer_provider_remote.dart';
import '../models/customer_provider.dart';

class CustomerProviderRepository {
  CustomerProviderRepository({CustomerProviderRemoteDataSource? remote})
    : _remote = remote ?? CustomerProviderRemoteDataSource();

  final CustomerProviderRemoteDataSource _remote;

  Future<List<CustomerProviderCategory>> categories() => _remote.categories();
  Future<CustomerProviderPage> providers({
    String? query,
    String? type,
    int page = 1,
  }) => _remote.providers(query: query, type: type, page: page);
  Future<CustomerProvider> provider(String id) => _remote.provider(id);
}
