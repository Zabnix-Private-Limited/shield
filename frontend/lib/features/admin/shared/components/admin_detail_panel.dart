import 'package:flutter/material.dart';

import 'admin_stat_card.dart';

class AdminDetailPanel extends StatelessWidget {
  const AdminDetailPanel({
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
    return AdminStatCard(title: title, subtitle: subtitle, child: child);
  }
}
