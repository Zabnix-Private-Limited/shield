import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import 'agent_design_system.dart';

class AgentPanelCard extends StatelessWidget {
  const AgentPanelCard({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.padding = AgentUi.panelPadding,
    this.minHeight,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight ?? 0),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.h5.copyWith(
                            color: AppColors.shieldNavy,
                          ),
                        ),
                        if ((subtitle ?? '').trim().isNotEmpty) ...[
                          AgentUi.gapH(AgentUi.space4),
                          Text(
                            subtitle!,
                            style: AppTypography.small.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (action != null) ...[
                    AgentUi.gapW(AgentUi.space12),
                    action!,
                  ],
                ],
              ),
              AgentUi.gapH(AgentUi.space16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class AgentWorkspaceSurface extends StatelessWidget {
  const AgentWorkspaceSurface({
    super.key,
    required this.child,
    this.padding = AgentSpacing.pageInsets,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: padding, child: child),
    );
  }
}

class AgentInsetSurface extends StatelessWidget {
  const AgentInsetSurface({
    super.key,
    required this.child,
    this.padding = AgentSpacing.contentInsets,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: AgentUi.radius(AgentRadius.panel),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: child,
    );
  }
}

class AgentMetricGrid extends StatelessWidget {
  const AgentMetricGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AgentUi.space12,
      runSpacing: AgentUi.space12,
      children: children,
    );
  }
}

class AgentMetricCard extends StatelessWidget {
  const AgentMetricCard({
    super.key,
    required this.value,
    required this.label,
    required this.helper,
    required this.icon,
    this.color,
    this.onTap,
    this.width = AgentUi.metricWidth,
    this.height = AgentUi.metricHeight,
  });

  final String value;
  final String label;
  final String helper;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Semantics(
          button: onTap != null,
          label: '$label: $value. $helper',
          child: InkWell(
            onTap: onTap,
            borderRadius: AgentUi.radius(AgentUi.radiusLarge),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: AgentUi.cardBodyPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: resolvedColor.withValues(alpha: 0.12),
                        borderRadius: AgentUi.radius(AgentUi.radiusMedium),
                      ),
                      child: Icon(
                        icon,
                        size: AgentUi.iconSize,
                        color: resolvedColor,
                      ),
                    ),
                    AgentUi.gapH(AgentUi.space20),
                    Text(
                      value,
                      style: AppTypography.h3.copyWith(
                        color: resolvedColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    AgentUi.gapH(AgentUi.space4),
                    Text(
                      label,
                      style: AppTypography.small.copyWith(
                        color: AppColors.shieldNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AgentUi.gapH(AgentUi.space4),
                    Text(
                      helper,
                      maxLines: 3,
                      overflow: TextOverflow.fade,
                      style: AppTypography.tiny.copyWith(color: AppColors.gray),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AgentStatusBadge extends StatelessWidget {
  const AgentStatusBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      constraints: const BoxConstraints(minHeight: AgentUi.touchTargetMin - 12),
      padding: AgentUi.chipPadding,
      decoration: BoxDecoration(
        borderRadius: AgentUi.radius(AgentUi.radiusPill),
        color: resolvedColor.withValues(alpha: 0.14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AgentUi.statusIconSize, color: resolvedColor),
            AgentUi.gapW(AgentUi.space8 - 2),
          ],
          Text(
            label,
            style: AppTypography.tiny.copyWith(
              color: resolvedColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AgentEmptyState extends StatelessWidget {
  const AgentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AgentUi.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: AgentUi.radius(AgentUi.radiusLarge),
                ),
                child: Icon(
                  icon,
                  size: AgentUi.iconSizeLarge,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              AgentUi.gapH(AgentUi.space16),
              Text(title, style: AppTypography.h5, textAlign: TextAlign.center),
              AgentUi.gapH(AgentUi.space8),
              Text(
                message,
                style: AppTypography.small.copyWith(color: AppColors.gray),
                textAlign: TextAlign.center,
              ),
              if ((actionLabel ?? '').trim().isNotEmpty &&
                  onAction != null) ...[
                AgentUi.gapH(AgentUi.space20),
                AgentSecondaryButton(onPressed: onAction, label: actionLabel!),
              ],
              if ((secondaryActionLabel ?? '').trim().isNotEmpty &&
                  onSecondaryAction != null) ...[
                AgentUi.gapH(AgentUi.space8),
                AgentGhostButton(
                  onPressed: onSecondaryAction,
                  label: secondaryActionLabel!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AgentLoadingState extends StatelessWidget {
  const AgentLoadingState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            AgentUi.gapH(AgentSpacing.md),
            Text(title, style: AppTypography.h5, textAlign: TextAlign.center),
            AgentUi.gapH(AgentSpacing.xs),
            Text(
              message,
              style: AppTypography.small.copyWith(color: AppColors.gray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AgentErrorState extends StatelessWidget {
  const AgentErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
    this.icon = Icons.error_outline_rounded,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AgentUi.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: AgentUi.radius(AgentUi.radiusLarge),
                ),
                child: Icon(
                  icon,
                  size: AgentUi.iconSizeLarge,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              AgentUi.gapH(AgentUi.space16),
              Text(title, style: AppTypography.h5, textAlign: TextAlign.center),
              AgentUi.gapH(AgentUi.space8),
              Text(
                message,
                style: AppTypography.small.copyWith(color: AppColors.gray),
                textAlign: TextAlign.center,
              ),
              AgentUi.gapH(AgentUi.space20),
              AgentPrimaryButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: retryLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AgentActionTile extends StatelessWidget {
  const AgentActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Semantics(
        button: true,
        label: label,
        child: AgentSecondaryButton(
          onPressed: onTap,
          icon: Icon(icon, size: AgentUi.iconSize),
          label: label,
        ),
      ),
    );
  }
}

class AgentPrimaryButton extends StatelessWidget {
  const AgentPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AgentUi.controlHeight,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AgentUi.space16),
          shape: RoundedRectangleBorder(
            borderRadius: AgentUi.radius(AgentUi.radiusMedium),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

class AgentSecondaryButton extends StatelessWidget {
  const AgentSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AgentUi.controlHeight,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AgentUi.space16),
          shape: RoundedRectangleBorder(
            borderRadius: AgentUi.radius(AgentUi.radiusMedium),
          ),
        ),
        onPressed: onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: Text(label),
      ),
    );
  }
}

class AgentGhostButton extends StatelessWidget {
  const AgentGhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AgentUi.controlHeight,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AgentUi.space12),
          shape: RoundedRectangleBorder(
            borderRadius: AgentUi.radius(AgentUi.radiusMedium),
          ),
        ),
        onPressed: onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: Text(label),
      ),
    );
  }
}
