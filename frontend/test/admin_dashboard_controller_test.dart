import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/admin/dashboard/application/admin_dashboard_controller.dart';
import 'package:shield/features/admin/dashboard/domain/entities/admin_dashboard_entity.dart';
import 'package:shield/features/admin/dashboard/domain/repositories/admin_dashboard_repository.dart';

void main() {
  group('AdminDashboardController', () {
    test('load populates dashboard state from repository', () async {
      final controller = AdminDashboardController(
        _FakeAdminDashboardRepository(
          dashboard: const AdminDashboardEntity(
            sectionKey: 'dashboard',
            title: 'Dashboard',
            summary: 'Live summary',
            actions: ['Refresh'],
            metrics: [
              AdminDashboardMetricEntity(
                label: 'Customers',
                value: '42',
                note: 'live',
              ),
            ],
            queueItems: [],
            recentItems: [],
            insightItems: [],
          ),
        ),
      );

      await controller.load();

      expect(controller.state.error, isNull);
      expect(controller.state.dashboard, isNotNull);
      expect(controller.state.dashboard?.metrics.first.value, '42');
    });

    test('refresh keeps last successful dashboard when refresh fails', () async {
      final repository = _FlakyAdminDashboardRepository();
      final controller = AdminDashboardController(repository);

      await controller.load();
      await controller.refresh();

      expect(controller.state.dashboard, isNotNull);
      expect(controller.state.dashboard?.title, 'Dashboard');
      expect(controller.state.error, isNotNull);
    });
  });
}

class _FakeAdminDashboardRepository implements AdminDashboardRepository {
  _FakeAdminDashboardRepository({required this.dashboard});

  final AdminDashboardEntity dashboard;

  @override
  Future<AdminDashboardEntity> load({bool forceRefresh = false}) async {
    return dashboard;
  }
}

class _FlakyAdminDashboardRepository implements AdminDashboardRepository {
  bool _loadedOnce = false;

  @override
  Future<AdminDashboardEntity> load({bool forceRefresh = false}) async {
    if (_loadedOnce && forceRefresh) {
      throw StateError('refresh failed');
    }
    _loadedOnce = true;
    return const AdminDashboardEntity(
      sectionKey: 'dashboard',
      title: 'Dashboard',
      summary: 'Live summary',
      actions: ['Refresh'],
      metrics: [
        AdminDashboardMetricEntity(
          label: 'Customers',
          value: '42',
          note: 'live',
        ),
      ],
      queueItems: [],
      recentItems: [],
      insightItems: [],
    );
  }
}
