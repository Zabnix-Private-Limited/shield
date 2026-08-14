import 'package:flutter_test/flutter_test.dart';
import 'package:shield/features/agent/shared/data/agent_portal_repository.dart';
import 'package:shield/features/agent/shared/presentation/controllers/agent_portal_controller.dart';

void main() {
  test('Customer 360 loads the selected customer timeline as the canonical Agent timeline', () async {
    final repository = _TimelineRepository();
    final controller = AgentPortalController(repository);
    await controller.refreshWorkspace();

    expect(controller.selectedCustomerId, 'customer-1');
    expect(repository.loadedCustomerId, 'customer-1');
    expect(controller.customerTimeline, [
      {'activityType': 'CRM_ACTIVITY', 'notes': 'Follow-up completed'},
    ]);
  });
}

class _TimelineRepository extends AgentPortalRepository {
  String? loadedCustomerId;
  @override Future<Map<String, dynamic>> getWorkspace() async => const {'customers': <Map<String, dynamic>>[], 'tasks': <Map<String, dynamic>>[], 'notifications': <Map<String, dynamic>>[], 'recentActivity': <Map<String, dynamic>>[], 'upcomingAppointments': <Map<String, dynamic>>[], 'summary': <String, dynamic>{}, 'performance': <String, dynamic>{}};
  @override Future<Map<String, dynamic>> getCustomers({String? query, String? status, String? membershipStatus, int page = 1, int pageSize = 25}) async => const {'items': [{'id': 'customer-1', 'firstName': 'Asha'}], 'page': 1, 'pageSize': 25, 'total': 1, 'totalPages': 1};
  @override Future<Map<String, dynamic>> getCustomerWorkspace(String customerId) async { loadedCustomerId = customerId; return const {'timeline': [{'activityType': 'CRM_ACTIVITY', 'notes': 'Follow-up completed'}]}; }
  @override Future<List<Map<String, dynamic>>> getProviders() async => const [];
  @override Future<List<Map<String, dynamic>>> getBusinesses() async => const [];
  @override Future<List<Map<String, dynamic>>> getMembershipTypes() async => const [];
  @override Future<Map<String, dynamic>> getReportRegistry() async => const {'reports': <Map<String, dynamic>>[]};
}
