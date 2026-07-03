import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import 'agent_design_system.dart';

class AgentSectionHeader extends StatelessWidget {
  const AgentSectionHeader({
    super.key,
    required this.title,
    required this.description,
    this.actions,
  });

  final String title;
  final String description;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 720;
    final actionWidgets = actions ?? const <Widget>[];
    final actionRow = actionWidgets.isEmpty
        ? null
        : Wrap(
            spacing: AgentUi.space8,
            runSpacing: AgentUi.space8,
            alignment: WrapAlignment.end,
            children: actionWidgets,
          );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h4),
          AgentUi.gapH(AgentSpacing.xxs),
          Text(
            description,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          if (actionRow != null) ...[AgentUi.gapH(AgentSpacing.sm), actionRow],
          AgentUi.gapH(AgentSpacing.sm),
          const Divider(height: 1),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h4),
                  AgentUi.gapH(AgentSpacing.xxs),
                  Text(
                    description,
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            ),
            if (actionRow != null) AgentUi.gapW(AgentUi.space16),
            if (actionRow != null) Flexible(child: actionRow),
          ],
        ),
        AgentUi.gapH(AgentSpacing.sm),
        const Divider(height: 1),
      ],
    );
  }
}
