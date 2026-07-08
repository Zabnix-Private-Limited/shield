import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/shield_brand_lockup.dart';
import '../../../portal/presentation/portal_role_data.dart';

class CustomerAppBar extends StatelessWidget {
  final PortalRoleData portal;
  final PortalSectionData section;
  final VoidCallback? onMenuPressed;
  final Widget? trailing;

  const CustomerAppBar({
    super.key,
    required this.portal,
    required this.section,
    this.onMenuPressed,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.shieldNavy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShieldBrandLockup(compact: true),
                const SizedBox(height: 10),
                Text(
                  section.title,
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  portal.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
