import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/shield_role.dart';

class CustomerBottomNavigation extends StatelessWidget {
  final String activeSectionKey;

  const CustomerBottomNavigation({super.key, required this.activeSectionKey});

  static const List<_CustomerBottomNavItem> _items = [
    _CustomerBottomNavItem(
      sectionKey: 'dashboard',
      label: 'Home',
      icon: Icons.home_rounded,
    ),
    _CustomerBottomNavItem(
      sectionKey: 'wallet',
      label: 'Wallet',
      icon: Icons.account_balance_wallet_rounded,
    ),
    _CustomerBottomNavItem(
      sectionKey: 'services',
      label: 'Services',
      icon: Icons.storefront_rounded,
    ),
    _CustomerBottomNavItem(
      sectionKey: 'appointments',
      label: 'Visits',
      icon: Icons.calendar_month_rounded,
    ),
    _CustomerBottomNavItem(
      sectionKey: 'profile',
      label: 'Profile',
      icon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _items.indexWhere(
      (item) => item.sectionKey == activeSectionKey,
    );
    final effectiveIndex = selectedIndex >= 0 ? selectedIndex : 0;

    return NavigationBar(
      height: 72,
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.shieldBlue.withValues(alpha: 0.12),
      selectedIndex: effectiveIndex,
      onDestinationSelected: (index) {
        final item = _items[index];
        if (item.sectionKey == activeSectionKey) {
          return;
        }
        context.go(
          '/portal/${SHIELDRole.customer.routeKey}/${item.sectionKey}',
        );
      },
      destinations: _items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.icon, color: AppColors.shieldBlue),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

class _CustomerBottomNavItem {
  final String sectionKey;
  final String label;
  final IconData icon;

  const _CustomerBottomNavItem({
    required this.sectionKey,
    required this.label,
    required this.icon,
  });
}
