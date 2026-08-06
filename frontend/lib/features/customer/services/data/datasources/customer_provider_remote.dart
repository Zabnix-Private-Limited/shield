import '../../../../../shared/services/api_service.dart';
import '../models/customer_provider.dart';

class CustomerProviderRemoteDataSource {
  Future<List<CustomerProviderCategory>> categories() async =>
      (await ApiService.getCustomerProviderCategories())
          .map(CustomerProviderCategory.fromJson)
          .toList();

  Future<CustomerProviderPage> providers({
    String? query,
    String? type,
    int page = 1,
  }) async => CustomerProviderPage.fromJson(
    await ApiService.getCustomerProviders(query: query, type: type, page: page),
  );

  Future<CustomerProvider> provider(String id) async =>
      CustomerProvider.fromJson(await ApiService.getCustomerProvider(id));
}
