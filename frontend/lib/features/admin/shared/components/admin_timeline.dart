import 'package:flutter/material.dart';

import '../models/admin_timeline_item.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminTimeline extends StatelessWidget {
  const AdminTimeline({
    super.key,
    required this.items,
  });

  final List<AdminTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: item.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.time,
                          style: AdminTypography.tiny.copyWith(
                            color: AdminColors.caption,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
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
                            height: 1.4,
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
