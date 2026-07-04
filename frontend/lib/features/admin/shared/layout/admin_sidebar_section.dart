import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_card.dart';
import '../theme/admin_typography.dart';

class AdminSidebarSection extends StatelessWidget {
  const AdminSidebarSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AdminTypography.tiny.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
