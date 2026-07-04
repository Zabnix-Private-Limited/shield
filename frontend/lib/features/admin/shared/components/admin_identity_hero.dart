import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';
import 'admin_status_badge.dart';

class AdminIdentityHero extends StatelessWidget {
  const AdminIdentityHero({
    super.key,
    required this.name,
    required this.code,
    required this.primaryMeta,
    required this.secondaryMeta,
    required this.badges,
  });

  final String name;
  final String code;
  final String primaryMeta;
  final String secondaryMeta;
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AdminColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              (name.isNotEmpty ? name[0] : '?').toUpperCase(),
              style: AdminTypography.h2.copyWith(
                color: AdminColors.surface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AdminTypography.h2.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AdminColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: AdminTypography.small.copyWith(
                    color: AdminColors.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  primaryMeta,
                  style: AdminTypography.small.copyWith(
                    color: AdminColors.subtext,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  secondaryMeta,
                  style: AdminTypography.tiny.copyWith(
                    color: AdminColors.caption,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges
                      .map(
                        (badge) => AdminStatusBadge(
                          label: badge,
                          color: AdminColors.secondary,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
