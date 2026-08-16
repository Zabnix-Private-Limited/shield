import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'customer_auth_session.dart';

class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    this.brand,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final String? brand;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'brand': brand,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? 'Product',
        brand: json['brand']?.toString(),
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
        quantity: Math.max(1, (json['quantity'] as num?)?.toInt() ?? 1),
      );

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        productName: productName,
        brand: brand,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
      );
}

class CustomerCartService extends ChangeNotifier {
  CustomerCartService._();

  static final CustomerCartService instance = CustomerCartService._();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const _guestCartKey = 'guest_cart_items_v1';

  List<CartItem> _items = const [];
  bool _initialized = false;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.lineTotal);
  bool get isEmpty => _items.isEmpty;

  String _getStorageKey() {
    final customerId = CustomerAuthSession.instance.customerId;
    if (customerId != null && customerId.isNotEmpty) {
      return 'customer_cart_items_${customerId}_v1';
    }
    return _guestCartKey;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await loadCart();
    CustomerAuthSession.instance.addListener(_handleAuthChange);
    _initialized = true;
  }

  Future<void> _handleAuthChange() async {
    final customerId = CustomerAuthSession.instance.customerId;
    if (customerId != null && customerId.isNotEmpty) {
      await mergeGuestCartOnLogin(customerId);
    } else {
      await loadCart();
    }
  }

  Future<void> loadCart() async {
    try {
      final key = _getStorageKey();
      final raw = await _storage.read(key: key);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items = decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => CartItem.fromJson(e))
            .where((e) => e.productId.isNotEmpty && e.quantity >= 1)
            .toList();
      } else {
        _items = const [];
      }
    } catch (_) {
      _items = const [];
    }
    notifyListeners();
  }

  Future<void> _persistCart() async {
    try {
      final key = _getStorageKey();
      if (_items.isEmpty) {
        await _storage.delete(key: key);
      } else {
        final payload = jsonEncode(_items.map((i) => i.toJson()).toList());
        await _storage.write(key: key, value: payload);
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> addItem({
    required String productId,
    required String productName,
    String? brand,
    required double unitPrice,
    int quantity = 1,
  }) async {
    final existingIndex = _items.indexWhere((i) => i.productId == productId);
    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      final updated = existing.copyWith(quantity: existing.quantity + quantity);
      _items = List.of(_items)..[existingIndex] = updated;
    } else {
      _items = [
        ..._items,
        CartItem(
          productId: productId,
          productName: productName,
          brand: brand,
          unitPrice: unitPrice,
          quantity: Math.max(1, quantity),
        ),
      ];
    }
    await _persistCart();
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(productId);
      return;
    }
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      _items = List.of(_items)..[index] = _items[index].copyWith(quantity: newQuantity);
      await _persistCart();
    }
  }

  Future<void> removeItem(String productId) async {
    _items = _items.where((i) => i.productId != productId).toList();
    await _persistCart();
  }

  Future<void> clearCart() async {
    _items = const [];
    await _persistCart();
  }

  Future<void> mergeGuestCartOnLogin(String customerId) async {
    try {
      final guestRaw = await _storage.read(key: _guestCartKey);
      if (guestRaw == null || guestRaw.trim().isEmpty) {
        await loadCart();
        return;
      }

      final guestItems = (jsonDecode(guestRaw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((e) => CartItem.fromJson(e))
          .where((e) => e.productId.isNotEmpty && e.quantity >= 1)
          .toList();

      if (guestItems.isEmpty) {
        await loadCart();
        return;
      }

      final customerKey = 'customer_cart_items_${customerId}_v1';
      final customerRaw = await _storage.read(key: customerKey);
      List<CartItem> customerItems = const [];
      if (customerRaw != null && customerRaw.trim().isNotEmpty) {
        customerItems = (jsonDecode(customerRaw) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map((e) => CartItem.fromJson(e))
            .where((e) => e.productId.isNotEmpty && e.quantity >= 1)
            .toList();
      }

      final mergedMap = <String, CartItem>{};
      for (final item in customerItems) {
        mergedMap[item.productId] = item;
      }
      for (final item in guestItems) {
        if (mergedMap.containsKey(item.productId)) {
          final existing = mergedMap[item.productId]!;
          mergedMap[item.productId] = existing.copyWith(
            quantity: existing.quantity + item.quantity,
          );
        } else {
          mergedMap[item.productId] = item;
        }
      }

      _items = mergedMap.values.toList();
      await _storage.write(
        key: customerKey,
        value: jsonEncode(_items.map((i) => i.toJson()).toList()),
      );
      await _storage.delete(key: _guestCartKey);
    } catch (_) {
      await loadCart();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitOrder({
    required String providerId,
    String? deliveryAddress,
    String? customerNotes,
  }) async {
    if (_items.isEmpty) {
      throw StateError('Cart is empty.');
    }

    final idempotencyKey =
        'CART-${DateTime.now().millisecondsSinceEpoch}-${_items.length}';
    final payload = {
      'provider_id': providerId,
      'items': _items
          .map((i) => {
                'product_id': i.productId,
                'quantity': i.quantity,
              })
          .toList(),
      if (deliveryAddress != null && deliveryAddress.trim().isNotEmpty)
        'delivery_address': deliveryAddress.trim(),
      if (customerNotes != null && customerNotes.trim().isNotEmpty)
        'customer_notes': customerNotes.trim(),
      'idempotency_key': idempotencyKey,
    };

    final order = await ApiService.submitCustomerOrder(payload);
    // Cart is cleared ONLY after server returns order success
    await clearCart();
    return order;
  }
}

class Math {
  static int max(int a, int b) => a > b ? a : b;
}
