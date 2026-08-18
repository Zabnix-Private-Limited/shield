import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../services/internal_auth_session.dart';

class GlobalRoleOption {
  final String key;
  final String label;
  final IconData icon;
  final String route;
  final String? backendRoleCode;

  const GlobalRoleOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.route,
    this.backendRoleCode,
  });
}

class GlobalRoleDropdown extends StatelessWidget {
  final bool compact;

  const GlobalRoleDropdown({super.key, this.compact = false});

  static const List<GlobalRoleOption> options = [
    GlobalRoleOption(
      key: 'customer',
      label: 'Customer App',
      icon: Icons.person_outline_rounded,
      route: '/portal/customer/dashboard',
    ),
    GlobalRoleOption(
      key: 'agent',
      label: 'SHIELD Agent',
      icon: Icons.badge_outlined,
      route: '/portal/agent/dashboard',
      backendRoleCode: 'SHIELD_AGENT',
    ),
    GlobalRoleOption(
      key: 'pharmacy',
      label: 'Pharmacist',
      icon: Icons.local_pharmacy_outlined,
      route: '/portal/provider/dashboard',
      backendRoleCode: 'PHARMACY_PROVIDER',
    ),
    GlobalRoleOption(
      key: 'lab',
      label: 'Laboratory',
      icon: Icons.biotech_outlined,
      route: '/portal/provider/dashboard',
      backendRoleCode: 'LAB_PROVIDER',
    ),
    GlobalRoleOption(
      key: 'admin',
      label: 'Super Admin',
      icon: Icons.admin_panel_settings_outlined,
      route: '/portal/super-admin/dashboard',
      backendRoleCode: 'ADMIN',
    ),
  ];

  GlobalRoleOption _resolveCurrentOption(String path) {
    if (path.contains('/portal/customer')) {
      return options[0];
    }
    if (path.contains('/portal/agent')) {
      return options[1];
    }
    if (path.contains('/portal/provider') || path.contains('/portal/pharmacy-staff')) {
      final currentRole = InternalAuthSession.instance.roleCode;
      if (currentRole == 'LAB_PROVIDER') {
        return options[3];
      }
      return options[2];
    }
    if (path.contains('/portal/super-admin') || path.contains('/portal/admin')) {
      return options[4];
    }
    return options[0];
  }

  void _onOptionSelected(BuildContext context, GlobalRoleOption option) {
    if (option.backendRoleCode != null) {
      InternalAuthSession.instance.setActiveRoleCode(option.backendRoleCode!);
    }
    context.go(option.route);
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();
    final currentOption = _resolveCurrentOption(currentPath);

    return PopupMenuButton<GlobalRoleOption>(
      onSelected: (option) => _onOptionSelected(context, option),
      tooltip: 'Switch Workspace / Role',
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.shieldNavy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.shieldNavy.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentOption.icon,
              size: compact ? 16 : 18,
              color: AppColors.shieldNavy,
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              Text(
                currentOption.label,
                style: AppTypography.tiny.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.shieldNavy,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: compact ? 18 : 20,
              color: AppColors.shieldNavy,
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => options.map((option) {
        final isSelected = option.key == currentOption.key;
        return PopupMenuItem<GlobalRoleOption>(
          value: option,
          child: Row(
            children: [
              Icon(
                option.icon,
                size: 20,
                color: isSelected ? AppColors.shieldNavy : AppColors.gray,
              ),
              const SizedBox(width: 12),
              Text(
                option.label,
                style: AppTypography.body.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.shieldNavy : AppColors.darkGray,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(Icons.check_rounded, size: 18, color: AppColors.shieldNavy),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
