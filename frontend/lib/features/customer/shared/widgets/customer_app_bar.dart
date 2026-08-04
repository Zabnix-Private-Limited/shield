import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/utils/app_display_formatters.dart';
import '../../../../shared/widgets/shield_brand_lockup.dart';
import '../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../portal/presentation/portal_role_data.dart';
import '../theme/customer_design_tokens.dart';

class CustomerAppBar extends StatefulWidget {
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
  State<CustomerAppBar> createState() => _CustomerAppBarState();
}

class _CustomerAppBarState extends State<CustomerAppBar> {
  late final DashboardController _dashboardController;

  bool get _isMainPage => const {
    'dashboard',
    'services',
    'appointments',
    'profile',
  }.contains(widget.section.key);

  @override
  void initState() {
    super.initState();
    _dashboardController = DashboardController()..load();
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/portal/customer/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMainPage) {
      return _SubPageHeader(
        title: widget.section.title,
        onBack: () => _goBack(context),
        trailing: widget.trailing,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: ListenableBuilder(
        listenable: _dashboardController,
        builder: (context, _) => _CustomerMainHeader(
          onMenuPressed: widget.onMenuPressed,
          onNotificationsPressed: () =>
              context.go('/portal/customer/notifications'),
          onWalletPressed: () => context.go('/portal/customer/wallet'),
          onRewardsPressed: () => context.go('/portal/customer/rewards'),
          cashBalance: _dashboardController.dashboard?.wallet.cashBalance,
          rewardPoints: _dashboardController.dashboard?.wallet.pointsBalance,
          unreadNotifications: _dashboardController.dashboard?.notifications
              .where((item) => !item.isRead)
              .length,
          isLoading:
              _dashboardController.isLoading && !_dashboardController.hasData,
          hasError:
              _dashboardController.error != null &&
              !_dashboardController.hasData,
          onRetry: _dashboardController.load,
        ),
      ),
    );
  }
}

class _SubPageHeader extends StatelessWidget {
  const _SubPageHeader({
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CustomerDesignTokens.sectionTitle,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _CustomerMainHeader extends StatelessWidget {
  const _CustomerMainHeader({
    required this.onMenuPressed,
    required this.onNotificationsPressed,
    required this.onWalletPressed,
    required this.onRewardsPressed,
    required this.cashBalance,
    required this.rewardPoints,
    required this.unreadNotifications,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  final VoidCallback? onMenuPressed;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onWalletPressed;
  final VoidCallback onRewardsPressed;
  final double? cashBalance;
  final double? rewardPoints;
  final int? unreadNotifications;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cashLabel = cashBalance == null
        ? (isLoading ? 'Loading' : '₹0')
        : AppDisplayFormatters.formatCurrencyString(
            cashBalance!.toStringAsFixed(0),
          );
    final rewardLabel = rewardPoints == null
        ? (isLoading ? 'Loading' : '0')
        : rewardPoints!.toStringAsFixed(0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // The preferred app-bar height is intentionally small on mobile.  Do
        // not let balances, the mark and two action buttons compete for the
        // same horizontal row on narrow web viewports.
        final compact = constraints.maxWidth < 560;
        final dense = constraints.maxWidth < 520;
        final iconOnly = constraints.maxWidth < 480;
        final controlSize = dense ? 40.0 : 48.0;

        return Row(
          children: [
            IconButton(
              onPressed: onMenuPressed,
              icon: Icon(Icons.menu_rounded, size: dense ? 21 : 24),
              tooltip: 'Open navigation menu',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: controlSize,
                height: controlSize,
              ),
              style: IconButton.styleFrom(
                backgroundColor: CustomerDesignTokens.surface,
                foregroundColor: AppColors.shieldNavy,
              ),
            ),
            if (!dense) ...[
              const SizedBox(width: 8),
              ShieldBrandLockup(compact: true, showWordmark: !compact),
            ],
            const Spacer(),
            _HeaderBalanceChip(
              icon: Icons.account_balance_wallet_rounded,
              label: compact ? null : 'Cash Wallet',
              value: cashLabel,
              color: CustomerDesignTokens.cash,
              onTap: onWalletPressed,
              dense: dense,
              iconOnly: iconOnly,
            ),
            SizedBox(width: dense ? 5 : 8),
            _HeaderBalanceChip(
              icon: Icons.workspace_premium_rounded,
              label: compact ? null : 'Reward Points',
              value: compact ? rewardLabel : '$rewardLabel pts',
              color: CustomerDesignTokens.reward,
              onTap: onRewardsPressed,
              dense: dense,
              iconOnly: iconOnly,
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: hasError ? onRetry : onNotificationsPressed,
                  icon: Icon(
                    hasError
                        ? Icons.refresh_rounded
                        : Icons.notifications_none_rounded,
                  ),
                  tooltip: hasError ? 'Retry account summary' : 'Notifications',
                  color: AppColors.shieldNavy,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(
                    width: controlSize,
                    height: controlSize,
                  ),
                ),
                if (!hasError && (unreadNotifications ?? 0) > 0)
                  Positioned(
                    right: 6,
                    top: 4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.shieldBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${(unreadNotifications ?? 0).clamp(0, 9)}',
                        style: AppTypography.tiny.copyWith(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeaderBalanceChip extends StatelessWidget {
  const _HeaderBalanceChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    required this.dense,
    required this.iconOnly,
  });

  final IconData icon;
  final String? label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  final bool dense;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomerDesignTokens.surface,
      borderRadius: BorderRadius.circular(CustomerDesignTokens.controlRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CustomerDesignTokens.controlRadius),
        child: Container(
          constraints: BoxConstraints(minHeight: dense ? 40 : 48),
          padding: iconOnly
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(
                  horizontal: label == null ? (dense ? 6 : 10) : 12,
                  vertical: dense ? 4 : 7,
                ),
          decoration: BoxDecoration(
            border: Border.all(color: CustomerDesignTokens.border),
            borderRadius: BorderRadius.circular(
              CustomerDesignTokens.controlRadius,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: iconOnly ? const EdgeInsets.all(10) : EdgeInsets.zero,
                child: Icon(icon, size: dense ? 18 : 20, color: color),
              ),
              if (!iconOnly && label != null) ...[
                const SizedBox(width: 7),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label!, style: CustomerDesignTokens.caption),
                    Text(
                      value,
                      style: AppTypography.small.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ] else if (!iconOnly) ...[
                SizedBox(width: dense ? 3 : 5),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: dense ? 62 : 96),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.tiny.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
