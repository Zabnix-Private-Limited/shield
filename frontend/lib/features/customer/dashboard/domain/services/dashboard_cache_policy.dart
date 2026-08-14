class DashboardCachePolicy {
  static const String boxName = 'customer_dashboard_cache';
  static const int contractVersion = 2;

  static String cacheKeyFor(String customerId) =>
      'customer_dashboard_v${contractVersion}_$customerId';
}
