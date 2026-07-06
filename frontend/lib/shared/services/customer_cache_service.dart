import 'package:hive/hive.dart';

import '../../features/customer/dashboard/domain/services/dashboard_cache_policy.dart';
import '../../features/customer/membership/domain/services/membership_cache_policy.dart';
import '../../features/customer/wallet/domain/services/wallet_cache_policy.dart';

class CustomerCacheService {
  const CustomerCacheService._();

  static Future<void> clearForCustomer(String? customerId) async {
    final normalized = customerId?.trim() ?? '';
    if (normalized.isEmpty) {
      return;
    }

    final dashboardBox = await Hive.openBox<String>(
      DashboardCachePolicy.boxName,
    );
    await dashboardBox.delete(DashboardCachePolicy.cacheKeyFor(normalized));

    final membershipBox = await Hive.openBox<String>(
      MembershipCachePolicy.boxName,
    );
    await membershipBox.delete(MembershipCachePolicy.cacheKeyFor(normalized));

    final walletBox = await Hive.openBox<String>(WalletCachePolicy.boxName);
    await walletBox.delete(WalletCachePolicy.cacheKeyFor(normalized));
  }
}
