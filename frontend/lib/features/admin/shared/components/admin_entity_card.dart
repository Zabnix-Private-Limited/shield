import 'package:flutter/material.dart';

import '../models/admin_entity_item.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';
import 'admin_status_badge.dart';

class AdminEntityCard extends StatelessWidget {
  const AdminEntityCard({super.key, required this.item});

  final AdminEntityItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.mutedSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: AdminTypography.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AdminColors.text,
                  ),
                ),
              ),
              AdminStatusBadge(label: item.status, color: item.color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.subtitle,
            style: AdminTypography.small.copyWith(
              color: AdminColors.subtext,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.meta,
            style: AdminTypography.tiny.copyWith(color: AdminColors.caption),
          ),
        ],
      ),
    );
  }
}
