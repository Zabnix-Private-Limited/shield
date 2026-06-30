import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/document.dart';
import '../../../../shared/services/api_service.dart';

class ProviderPortalRepository {
  Future<Map<String, dynamic>> getOperationalWorkspace() async {
    return await ApiService.getProviderWorkspace(limit: 20) ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getPlatformWorkspace({
    bool forceRefresh = false,
  }) async {
    return await ApiService.getProviderPlatformWorkspace(
          forceRefresh: forceRefresh,
        ) ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getAuthenticatedProfile() {
    return ApiService.getAuthenticatedProfile();
  }

  Future<Customer> getCustomerProfile(String customerId) {
    return ApiService.getCustomerProfile(customerId);
  }

  Future<Map<String, dynamic>> getCustomerWallet(String customerId) {
    return ApiService.getCustomerWalletBundle(customerId);
  }

  Future<Map<String, dynamic>> getCustomerMembership(String customerId) {
    return ApiService.getCustomerMembershipBundle(customerId);
  }

  Future<List<Document>> getCustomerDocuments(String customerId) {
    return ApiService.getCustomerDocumentsStrict(customerId);
  }

  Future<List<Appointment>> getCustomerAppointments(String customerId) {
    return ApiService.getAppointmentsByCustomerId(customerId);
  }

  Future<Map<String, dynamic>> getConsultationWorkspace(String appointmentId) {
    return ApiService.getAppointmentConsultationWorkspace(appointmentId);
  }

  Future<Map<String, dynamic>> startConsultation(String appointmentId) {
    return ApiService.startAppointmentConsultation(appointmentId);
  }

  Future<Map<String, dynamic>> saveConsultation(
    String appointmentId,
    Map<String, dynamic> payload,
  ) {
    return ApiService.saveAppointmentConsultation(appointmentId, payload);
  }

  Future<Map<String, dynamic>> completeConsultation(
    String appointmentId,
    Map<String, dynamic> payload,
  ) {
    return ApiService.completeAppointmentConsultation(appointmentId, payload);
  }

  Future<List<Map<String, dynamic>>> getSessions() {
    return ApiService.getAuthenticatedSessions();
  }

  Future<List<Map<String, dynamic>>> getLoginHistory() {
    return ApiService.getLoginHistory();
  }

  Future<void> revokeSession(String sessionId) {
    return ApiService.revokeSession(sessionId);
  }
}
