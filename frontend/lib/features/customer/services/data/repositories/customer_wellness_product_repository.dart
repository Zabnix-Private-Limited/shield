import '../../../../../shared/services/api_service.dart';
import '../models/customer_wellness_product.dart';

class CustomerWellnessProductRepository {
  static const _pageSize = 12;

  Future<CustomerWellnessProductPage> products({
    String? query,
    String? categoryId,
    int page = 1,
  }) async => CustomerWellnessProductPage.fromJson(
    await ApiService.getCustomerWellnessProducts(
      query: query,
      categoryId: categoryId,
      page: page,
      pageSize: _pageSize,
    ),
  );
}
