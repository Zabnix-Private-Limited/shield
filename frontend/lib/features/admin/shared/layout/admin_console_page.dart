import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_button.dart';
import '../models/admin_action_item.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminConsolePage extends StatelessWidget {
  const AdminConsolePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const <AdminActionItem>[],
    this.toolbar,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<AdminActionItem> actions;
  final Widget? toolbar;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 1200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderText(title: title, subtitle: subtitle),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _HeaderActions(actions: actions),
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _HeaderText(title: title, subtitle: subtitle)),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 20),
                    _HeaderActions(actions: actions),
                  ],
                ],
              ),
        if (toolbar != null) ...[
          const SizedBox(height: 18),
          toolbar!,
        ],
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AdminTypography.h2.copyWith(
            color: AdminColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Text(
            subtitle,
            style: AdminTypography.small.copyWith(
              color: AdminColors.caption,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.actions});

  final List<AdminActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: actions
          .take(2)
          .toList()
          .reversed
          .map(
            (action) => SizedBox(
              width: 176,
              child: AppButton(
                text: action.label,
                onPressed: () {},
                type: action == actions.first
                    ? AppButtonType.primary
                    : AppButtonType.secondary,
              ),
            ),
          )
          .toList()
          .reversed
          .toList(),
    );
  }
}
