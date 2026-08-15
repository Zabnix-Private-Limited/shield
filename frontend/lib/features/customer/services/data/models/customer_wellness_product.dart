class CustomerWellnessProduct {
  const CustomerWellnessProduct({
    required this.id,
    required this.name,
    required this.catalogueKind,
    required this.purchasable,
    this.code,
    this.brand,
    this.unit,
    this.mrp,
    this.sellingPrice,
    this.categoryId,
    this.categoryName,
    this.purchasabilityReason,
  });

  final String id;
  final String name;
  final String catalogueKind;
  final bool purchasable;
  final String? code;
  final String? brand;
  final String? unit;
  final num? mrp;
  final num? sellingPrice;
  final String? categoryId;
  final String? categoryName;
  final String? purchasabilityReason;

  factory CustomerWellnessProduct.fromJson(Map<String, dynamic> json) {
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : const <String, dynamic>{};
    return CustomerWellnessProduct(
      id: json['id'].toString(),
      name: (json['productName'] ?? 'Wellness product').toString(),
      catalogueKind: (json['catalogueKind'] ?? 'STANDARD').toString(),
      purchasable: json['purchasable'] == true,
      code: json['productCode']?.toString(),
      brand: json['brand']?.toString(),
      unit: json['unit']?.toString(),
      mrp: json['mrp'] as num?,
      sellingPrice: json['sellingPrice'] as num?,
      categoryId: category['id']?.toString(),
      categoryName: category['name']?.toString(),
      purchasabilityReason: json['purchasabilityReason']?.toString(),
    );
  }
}

class CustomerWellnessProductCategory {
  const CustomerWellnessProductCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory CustomerWellnessProductCategory.fromJson(Map<String, dynamic> json) =>
      CustomerWellnessProductCategory(
        id: json['id'].toString(),
        name: (json['name'] ?? 'Uncategorised').toString(),
      );
}

class CustomerWellnessProductPage {
  const CustomerWellnessProductPage({
    required this.items,
    required this.categories,
    required this.page,
    required this.totalPages,
    this.disclosure,
  });

  final List<CustomerWellnessProduct> items;
  final List<CustomerWellnessProductCategory> categories;
  final int page;
  final int totalPages;
  final String? disclosure;

  factory CustomerWellnessProductPage.fromJson(Map<String, dynamic> json) {
    final pagination = Map<String, dynamic>.from(
      json['pagination'] as Map? ?? const <String, dynamic>{},
    );
    return CustomerWellnessProductPage(
      items: (json['items'] as List? ?? const [])
          .map(
            (item) => CustomerWellnessProduct.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      categories: (json['categories'] as List? ?? const [])
          .map(
            (item) => CustomerWellnessProductCategory.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      disclosure: json['disclosure']?.toString(),
    );
  }
}
