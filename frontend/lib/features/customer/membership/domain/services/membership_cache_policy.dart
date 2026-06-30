class MembershipCachePolicy {
  static const boxName = 'customer_membership';
  static String cacheKeyFor(String customerId) => 'current_membership_$customerId';

  const MembershipCachePolicy._();
}
