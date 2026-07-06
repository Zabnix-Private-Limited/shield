import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminBuilderStepItem {
  const AdminBuilderStepItem({
    required this.step,
    required this.label,
    required this.description,
  });

  final String step;
  final String label;
  final String description;
}

class AdminBuilderSteps extends StatelessWidget {
  const AdminBuilderSteps({super.key, required this.steps});

  final List<AdminBuilderStepItem> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AdminColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.step,
                      style: AdminTypography.small.copyWith(
                        color: AdminColors.surface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: AdminTypography.small.copyWith(
                            color: AdminColors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: AdminTypography.small.copyWith(
                            color: AdminColors.subtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
