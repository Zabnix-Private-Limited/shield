class AdminDashboardMetricEntity {
  const AdminDashboardMetricEntity({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;
}

class AdminDashboardRecordEntity {
  const AdminDashboardRecordEntity({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String status;
}

class AdminDashboardEntity {
  const AdminDashboardEntity({
    required this.sectionKey,
    required this.title,
    required this.summary,
    required this.actions,
    required this.metrics,
    required this.queueItems,
    required this.recentItems,
    required this.insightItems,
  });

  final String sectionKey;
  final String title;
  final String summary;
  final List<String> actions;
  final List<AdminDashboardMetricEntity> metrics;
  final List<AdminDashboardRecordEntity> queueItems;
  final List<AdminDashboardRecordEntity> recentItems;
  final List<AdminDashboardRecordEntity> insightItems;
}
