import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';

class AgentUi {
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;

  static const double radiusSmall = 14;
  static const double radiusMedium = 18;
  static const double radiusLarge = 22;
  static const double radiusPill = 999;

  static const double iconSize = 20;
  static const double iconSizeLarge = 24;
  static const double statusIconSize = 14;
  static const double touchTargetMin = 44;
  static const double controlHeight = 52;
  static const double metricWidth = 220;
  static const double metricHeight = 152;

  static const EdgeInsets panelPadding = EdgeInsets.all(space20);
  static const EdgeInsets compactPanelPadding = EdgeInsets.all(space16);
  static const EdgeInsets cardBodyPadding = EdgeInsets.all(space16);
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: space12, vertical: space8);

  static SizedBox gapH(double value) => SizedBox(height: value);
  static SizedBox gapW(double value) => SizedBox(width: value);

  static BorderRadius radius(double value) => BorderRadius.circular(value);

  static Color statusColor(BuildContext context, String? rawStatus) {
    switch ((rawStatus ?? '').trim().toUpperCase()) {
      case 'ACTIVE':
      case 'APPROVED':
      case 'AVAILABLE':
      case 'COMPLETED':
      case 'CONFIRMED':
      case 'UPLOADED':
      case 'VALIDATED':
      case 'VERIFIED':
        return AppColors.success;
      case 'CANCELLED':
      case 'FAILED':
      case 'INACTIVE':
      case 'MISSING':
      case 'REJECTED':
        return AppColors.error;
      case 'PENDING':
      case 'PAUSED':
        return AppColors.warning;
      case 'PROCESSING':
        return const Color(0xFFF97316);
      default:
        return AppColors.info;
    }
  }
}

class AgentFormFieldWidth extends StatelessWidget {
  const AgentFormFieldWidth({
    super.key,
    required this.child,
    this.width = 280,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class AgentSearchField extends StatelessWidget {
  const AgentSearchField({
    super.key,
    this.controller,
    this.labelText = 'Search',
    this.hintText,
    this.onChanged,
    this.width = 280,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final double width;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AgentFormFieldWidth(
      width: width,
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_outlined),
        ),
      ),
    );
  }
}

class AgentFilterWrap extends StatelessWidget {
  const AgentFilterWrap({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AgentUi.space12,
      runSpacing: AgentUi.space12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class AgentKeyValueItem extends StatelessWidget {
  const AgentKeyValueItem({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AgentUi.cardBodyPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: AgentUi.radius(AgentUi.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AgentUi.iconSize,
              color: Theme.of(context).colorScheme.primary,
            ),
            AgentUi.gapH(AgentUi.space12),
          ],
          Text(
            label,
            style: AppTypography.tiny.copyWith(
              color: AppColors.gray,
              fontWeight: FontWeight.w700,
            ),
          ),
          AgentUi.gapH(AgentUi.space4),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: AppColors.shieldNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
