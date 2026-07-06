import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_card.dart';
import '../models/admin_metric.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({super.key, required this.metric});

  final AdminMetric metric;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(metric.icon, color: metric.color, size: 18),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  metric.label,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  style: AdminTypography.tiny.copyWith(
                    color: AdminColors.caption,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metric.value,
            style: AdminTypography.h2.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AdminColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.note,
            style: AdminTypography.small.copyWith(color: AdminColors.subtext),
          ),
        ],
      ),
    );
  }
}
