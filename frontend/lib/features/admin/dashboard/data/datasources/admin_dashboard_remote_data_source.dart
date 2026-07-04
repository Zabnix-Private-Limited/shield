import '../../../../../shared/models/shield_role.dart';
import '../../../../../shared/services/api_service.dart';
import '../../api/admin_dashboard_endpoints.dart';
import '../dto/admin_dashboard_dto.dart';

class AdminDashboardRemoteDataSource {
  Future<AdminDashboardDto> fetch() async {
    final section = await ApiService.getRoleSectionData(
      SHIELDRole.superAdmin,
      AdminDashboardEndpoints.sectionKey,
    );
    return AdminDashboardDto.fromPortalSectionData(section);
  }
}
