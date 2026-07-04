import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_card.dart';
import 'admin_section_header.dart';

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
