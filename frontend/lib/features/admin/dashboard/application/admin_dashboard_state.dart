import '../domain/entities/admin_dashboard_entity.dart';

class AdminDashboardState {
  const AdminDashboardState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.dashboard,
  });

  final bool isLoading;
  final bool isRefreshing;
  final Object? error;
  final AdminDashboardEntity? dashboard;

  bool get hasData => dashboard != null;

  AdminDashboardState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    Object? error = _sentinel,
    AdminDashboardEntity? dashboard = _sentinelDashboard,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: identical(error, _sentinel) ? this.error : error,
      dashboard: identical(dashboard, _sentinelDashboard)
          ? this.dashboard
          : dashboard,
    );
  }
}

const Object _sentinel = Object();
const AdminDashboardEntity _sentinelDashboard = AdminDashboardEntity(
  sectionKey: '',
  title: '',
  summary: '',
  actions: <String>[],
  metrics: <AdminDashboardMetricEntity>[],
  queueItems: <AdminDashboardRecordEntity>[],
  recentItems: <AdminDashboardRecordEntity>[],
  insightItems: <AdminDashboardRecordEntity>[],
);
