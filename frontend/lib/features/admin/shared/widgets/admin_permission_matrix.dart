import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminPermissionMatrix extends StatelessWidget {
  const AdminPermissionMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    const headers = ['Role', 'Customers', 'Documents', 'Wallet', 'Audit'];
    const rows = [
      ['ADMIN', 'Full', 'Full', 'Full', 'Full'],
      ['SHIELD_AGENT', 'Scoped', 'Scoped', 'Hidden', 'Hidden'],
      ['CRM_EXECUTIVE', 'Assigned', 'Limited', 'Hidden', 'Hidden'],
      ['PROVIDER', 'Patient only', 'Clinical only', 'Hidden', 'Hidden'],
    ];

    return Column(
      children: [
        Row(
          children: headers
              .map(
                (cell) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      cell,
                      style: AdminTypography.tiny.copyWith(
                        color: AdminColors.caption,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (row) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: AdminColors.mutedSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: row
                  .map(
                    (cell) => Expanded(
                      child: Text(
                        cell,
                        style: AdminTypography.small.copyWith(
                          color: AdminColors.subtext,
                          fontWeight: cell == row.first ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
