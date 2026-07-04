import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_card.dart';
import '../models/admin_metric.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    super.key,
    required this.metric,
  });

  final AdminMetric metric;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(metric.icon, color: metric.color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminColors.mutedSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  metric.label,
                  style: AdminTypography.tiny.copyWith(
                    color: AdminColors.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            metric.value,
            style: AdminTypography.h2.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AdminColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.note,
            style: AdminTypography.small.copyWith(
              color: AdminColors.subtext,
            ),
          ),
        ],
      ),
    );
  }
}
