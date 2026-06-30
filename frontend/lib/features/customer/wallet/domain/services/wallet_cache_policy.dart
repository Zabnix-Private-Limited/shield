class WalletCachePolicy {
  static const String boxName = 'customer_wallet_cache';
  static String cacheKeyFor(String customerId) => 'customer_wallet_$customerId';
}
