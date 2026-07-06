import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_button.dart';
import '../models/admin_action_item.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminWorkspaceHeader extends StatelessWidget {
  const AdminWorkspaceHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.primaryAction,
    this.secondaryAction,
  });

  final String eyebrow;
  final String title;
  final String description;
  final AdminActionItem? primaryAction;
  final AdminActionItem? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 1240;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminColors.border),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderText(
                  eyebrow: eyebrow,
                  title: title,
                  description: description,
                ),
                const SizedBox(height: 16),
                _HeaderActions(
                  primaryAction: primaryAction,
                  secondaryAction: secondaryAction,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HeaderText(
                    eyebrow: eyebrow,
                    title: title,
                    description: description,
                  ),
                ),
                const SizedBox(width: 20),
                _HeaderActions(
                  primaryAction: primaryAction,
                  secondaryAction: secondaryAction,
                ),
              ],
            ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AdminTypography.tiny.copyWith(
            color: AdminColors.caption,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AdminTypography.h1.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AdminColors.text,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Text(
            description,
            style: AdminTypography.body.copyWith(
              color: AdminColors.subtext,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.primaryAction,
    required this.secondaryAction,
  });

  final AdminActionItem? primaryAction;
  final AdminActionItem? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final visibleActions = [
      if (secondaryAction?.onPressed != null) secondaryAction!,
      if (primaryAction?.onPressed != null) primaryAction!,
    ];
    if (visibleActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (secondaryAction?.onPressed != null)
          AppButton(
            text: secondaryAction!.label,
            onPressed: secondaryAction!.onPressed!,
            type: AppButtonType.secondary,
          ),
        if (primaryAction?.onPressed != null)
          AppButton(
            text: primaryAction!.label,
            onPressed: primaryAction!.onPressed!,
          ),
      ],
    );
  }
}
