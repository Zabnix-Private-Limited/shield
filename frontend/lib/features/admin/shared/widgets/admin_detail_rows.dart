import 'package:flutter/material.dart';

import '../models/admin_detail_item.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_typography.dart';

class AdminDetailRows extends StatelessWidget {
  const AdminDetailRows({
    super.key,
    required this.rows,
  });

  final List<AdminDetailItem> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      row.label,
                      style: AdminTypography.small.copyWith(
                        color: AdminColors.caption,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.value,
                      style: AdminTypography.small.copyWith(
                        color: AdminColors.subtext,
                        fontWeight: FontWeight.w700,
                      ),
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
