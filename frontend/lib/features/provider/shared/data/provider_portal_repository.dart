import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/customer.dart';
import '../../../../shared/models/document.dart';
import '../../../../shared/models/notification.dart';
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

  Future<Map<String, dynamic>> getPatientWorkspace(String customerId) {
    return ApiService.getProviderPatientWorkspace(customerId);
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

  Future<String> getDocumentDownloadUrl(String documentId) {
    return ApiService.getDocumentDownloadUrl(documentId);
  }

  Future<List<NotificationModel>> getCustomerNotifications(String customerId) {
    return ApiService.getCustomerNotificationsStrict(customerId);
  }

  Future<List<Map<String, dynamic>>> getCustomerPurchases(String customerId) {
    return ApiService.getCustomerPurchases(customerId);
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

  Future<Map<String, dynamic>> saveVisitBilling(
    String appointmentId,
    Map<String, dynamic> payload,
  ) {
    return ApiService.saveAppointmentVisitBilling(appointmentId, payload);
  }

  Future<Map<String, dynamic>> generateVisitInvoice(
    String appointmentId,
    Map<String, dynamic> payload,
  ) {
    return ApiService.generateAppointmentVisitInvoice(appointmentId, payload);
  }

  Future<Map<String, dynamic>> recordVisitPayment(
    String appointmentId,
    Map<String, dynamic> payload,
  ) {
    return ApiService.recordAppointmentVisitPayment(appointmentId, payload);
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) {
    return ApiService.searchProducts(query);
  }

  Future<Map<String, dynamic>> savePrescriptionDraft(
    String appointmentId,
    Map<String, dynamic> payload,
  ) {
    return ApiService.saveAppointmentPrescriptionDraft(appointmentId, payload);
  }

  Future<Map<String, dynamic>> finalizePrescription(
    String appointmentId,
    Map<String, dynamic> payload,
  ) {
    return ApiService.finalizeAppointmentPrescription(appointmentId, payload);
  }

  Future<Map<String, dynamic>> duplicatePreviousPrescription(
    String appointmentId,
  ) {
    return ApiService.duplicateAppointmentPrescription(appointmentId);
  }

  Future<Map<String, dynamic>> voidVisitInvoice(
    String appointmentId, {
    String? reason,
  }) {
    return ApiService.voidAppointmentVisitInvoice(
      appointmentId,
      reason: reason,
    );
  }

  Future<Appointment> confirmAppointment(String appointmentId) {
    return ApiService.confirmProviderAppointment(appointmentId);
  }

  Future<Appointment> cancelAppointment(String appointmentId) {
    return ApiService.cancelProviderAppointment(appointmentId);
  }

  Future<Map<String, dynamic>> generatePlatformPrint(
    String templateId,
    Map<String, dynamic> payload,
  ) {
    return ApiService.generatePlatformPrint(
      templateId: templateId,
      payload: payload,
    );
  }

  Future<Map<String, dynamic>> runPlatformReport({
    required String reportId,
    String workspace = 'provider',
    String format = 'PDF',
    String? providerId,
    String? businessId,
  }) {
    return ApiService.runPlatformReport(
      reportId: reportId,
      workspace: workspace,
      format: format,
      providerId: providerId,
      businessId: businessId,
    );
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
