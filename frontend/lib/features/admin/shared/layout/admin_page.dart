import 'package:flutter/material.dart';

import '../components/admin_metric_card.dart';
import '../components/admin_workspace_header.dart';
import '../models/admin_action_item.dart';
import '../models/admin_metric.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
    this.metrics = const <AdminMetric>[],
    this.primaryAction,
    this.secondaryAction,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;
  final List<AdminMetric> metrics;
  final AdminActionItem? primaryAction;
  final AdminActionItem? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminWorkspaceHeader(
          eyebrow: eyebrow,
          title: title,
          description: description,
          primaryAction: primaryAction,
          secondaryAction: secondaryAction,
        ),
        if (metrics.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: metrics
                .map(
                  (metric) => SizedBox(
                    width: _metricWidth(context),
                    child: AdminMetricCard(metric: metric),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  double _metricWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1600) return 168;
    if (width >= 1280) return 164;
    if (width >= 1024) return 200;
    return width - 80;
  }
}
