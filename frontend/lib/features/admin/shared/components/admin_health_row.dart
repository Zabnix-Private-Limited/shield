import 'package:flutter/material.dart';

import '../models/admin_health_item.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminHealthRow extends StatelessWidget {
  const AdminHealthRow({super.key, required this.item});

  final AdminHealthItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AdminTypography.small.copyWith(
                    color: AdminColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.meta,
                  style: AdminTypography.tiny.copyWith(
                    color: AdminColors.caption,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.value,
            style: AdminTypography.body.copyWith(
              color: item.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
