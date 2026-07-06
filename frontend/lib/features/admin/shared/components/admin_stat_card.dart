import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_card.dart';
import 'admin_section_header.dart';

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(compact ? 14 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(title: title, subtitle: subtitle),
          SizedBox(height: compact ? 12 : 14),
          child,
        ],
      ),
    );
  }
}
