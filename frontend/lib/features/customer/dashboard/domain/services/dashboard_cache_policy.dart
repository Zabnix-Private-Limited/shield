class DashboardCachePolicy {
  static const String boxName = 'customer_dashboard_cache';

  static String cacheKeyFor(String customerId) =>
      'customer_dashboard_$customerId';
}
