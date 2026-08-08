import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/customer/services/data/models/customer_provider.dart';
import 'package:shield/features/customer/services/data/repositories/customer_provider_repository.dart';
import 'package:shield/features/customer/services/presentation/controllers/customer_services_controller.dart';

void main() {
  test(
    'restores the route-recorded category, query, and loaded pages',
    () async {
      final repository = _Repository();
      final controller = CustomerServicesController(repository: repository);

      await controller.restore(
        query: '  shield  ',
        type: 'PHARMACY',
        loadedPage: 2,
      );

      expect(controller.query, 'shield');
      expect(controller.selectedType, 'PHARMACY');
      expect(repository.requests, [1, 2]);
      expect(controller.page.page, 2);
      expect(controller.page.items.map((provider) => provider.id), ['1', '2']);
    },
  );
}

class _Repository extends CustomerProviderRepository {
  final requests = <int>[];

  @override
  Future<List<CustomerProviderCategory>> categories() async => const [
    CustomerProviderCategory(
      code: 'PHARMACY',
      label: 'Pharmacy',
      providerCount: 2,
    ),
  ];

  @override
  Future<CustomerProviderPage> providers({
    String? query,
    String? type,
    int page = 1,
  }) async {
    requests.add(page);
    return CustomerProviderPage(
      items: [
        CustomerProvider(
          id: '$page',
          name: 'Provider $page',
          type: type ?? 'GENERAL',
          typeLabel: 'Pharmacy',
          availabilityLabel: 'Active provider',
        ),
      ],
      page: page,
      totalPages: 2,
    );
  }
}
