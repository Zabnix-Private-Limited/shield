import '../entities/admin_dashboard_entity.dart';

abstract class AdminDashboardRepository {
  Future<AdminDashboardEntity> load({bool forceRefresh = false});
}
