import '../../../../portal/presentation/portal_role_data.dart';
import '../../domain/entities/admin_dashboard_entity.dart';

class AdminDashboardMetricDto {
  const AdminDashboardMetricDto({
    required this.label,
    required this.value,
    required this.note,
  });

  factory AdminDashboardMetricDto.fromPortalMetric(PortalMetric metric) {
    return AdminDashboardMetricDto(
      label: metric.label,
      value: metric.value,
      note: metric.note,
    );
  }

  final String label;
  final String value;
  final String note;

  AdminDashboardMetricEntity toEntity() {
    return AdminDashboardMetricEntity(label: label, value: value, note: note);
  }
}

class AdminDashboardRecordDto {
  const AdminDashboardRecordDto({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.status,
  });

  factory AdminDashboardRecordDto.fromPortalListItem(PortalListItem item) {
    return AdminDashboardRecordDto(
      title: item.title,
      subtitle: item.subtitle,
      meta: item.meta,
      status: item.status,
    );
  }

  final String title;
  final String subtitle;
  final String meta;
  final String status;

  AdminDashboardRecordEntity toEntity() {
    return AdminDashboardRecordEntity(
      title: title,
      subtitle: subtitle,
      meta: meta,
      status: status,
    );
  }
}

class AdminDashboardDto {
  const AdminDashboardDto({
    required this.sectionKey,
    required this.title,
    required this.summary,
    required this.actions,
    required this.metrics,
    required this.queueItems,
    required this.recentItems,
    required this.insightItems,
  });

  factory AdminDashboardDto.fromPortalSectionData(PortalSectionData section) {
    return AdminDashboardDto(
      sectionKey: section.key,
      title: section.title,
      summary: section.summary,
      actions: List<String>.from(section.actions),
      metrics: section.metrics
          .map(AdminDashboardMetricDto.fromPortalMetric)
          .toList(),
      queueItems: section.queueItems
          .map(AdminDashboardRecordDto.fromPortalListItem)
          .toList(),
      recentItems: section.recentItems
          .map(AdminDashboardRecordDto.fromPortalListItem)
          .toList(),
      insightItems: section.insightItems
          .map(AdminDashboardRecordDto.fromPortalListItem)
          .toList(),
    );
  }

  final String sectionKey;
  final String title;
  final String summary;
  final List<String> actions;
  final List<AdminDashboardMetricDto> metrics;
  final List<AdminDashboardRecordDto> queueItems;
  final List<AdminDashboardRecordDto> recentItems;
  final List<AdminDashboardRecordDto> insightItems;

  AdminDashboardEntity toEntity() {
    return AdminDashboardEntity(
      sectionKey: sectionKey,
      title: title,
      summary: summary,
      actions: actions,
      metrics: metrics.map((metric) => metric.toEntity()).toList(),
      queueItems: queueItems.map((item) => item.toEntity()).toList(),
      recentItems: recentItems.map((item) => item.toEntity()).toList(),
      insightItems: insightItems.map((item) => item.toEntity()).toList(),
    );
  }
}
