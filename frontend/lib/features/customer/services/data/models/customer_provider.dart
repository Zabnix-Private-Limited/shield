class CustomerProvider {
  const CustomerProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.availabilityLabel,
    this.businessName,
  });

  final String id;
  final String name;
  final String type;
  final String typeLabel;
  final String availabilityLabel;
  final String? businessName;

  factory CustomerProvider.fromJson(Map<String, dynamic> json) =>
      CustomerProvider(
        id: json['id'].toString(),
        name: (json['name'] ?? 'SHIELD provider').toString(),
        type: (json['type'] ?? 'GENERAL').toString(),
        typeLabel: (json['typeLabel'] ?? 'Service provider').toString(),
        availabilityLabel:
            (json['availabilityLabel'] ?? 'Availability unavailable')
                .toString(),
        businessName: json['businessName']?.toString(),
      );
}

class CustomerProviderCategory {
  const CustomerProviderCategory({
    required this.code,
    required this.label,
    required this.providerCount,
  });

  final String code;
  final String label;
  final int providerCount;

  factory CustomerProviderCategory.fromJson(Map<String, dynamic> json) =>
      CustomerProviderCategory(
        code: json['code'].toString(),
        label: json['label'].toString(),
        providerCount: (json['providerCount'] as num?)?.toInt() ?? 0,
      );
}

class CustomerProviderPage {
  const CustomerProviderPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<CustomerProvider> items;
  final int page;
  final int totalPages;

  factory CustomerProviderPage.fromJson(Map<String, dynamic> json) {
    final pagination = Map<String, dynamic>.from(
      json['pagination'] as Map? ?? const {},
    );
    return CustomerProviderPage(
      items: (json['items'] as List? ?? const [])
          .map(
            (item) => CustomerProvider.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
