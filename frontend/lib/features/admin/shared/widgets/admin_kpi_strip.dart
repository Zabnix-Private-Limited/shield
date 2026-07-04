import 'package:flutter/material.dart';

import '../models/admin_kpi_item.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminKpiStrip extends StatelessWidget {
  const AdminKpiStrip({
    super.key,
    required this.items,
  });

  final List<AdminKpiItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Container(
              width: 146,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminColors.mutedSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AdminTypography.tiny.copyWith(
                      color: AdminColors.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.value,
                    style: AdminTypography.body.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.note,
                    style: AdminTypography.tiny.copyWith(color: AdminColors.caption),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
