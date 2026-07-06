import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';
import 'admin_status_badge.dart';

class AdminQueueTile extends StatelessWidget {
  const AdminQueueTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AdminColors.mutedSurface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AdminTypography.small.copyWith(
                          color: AdminColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    AdminStatusBadge(label: status, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AdminTypography.small.copyWith(
                    color: AdminColors.subtext,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
