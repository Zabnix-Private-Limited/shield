import 'dart:typed_data';

import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/document.dart';
import '../../../../shared/services/api_service.dart';

class AgentPortalRepository {
  Future<Map<String, dynamic>> getWorkspace() => ApiService.getAgentWorkspace();

  Future<Map<String, dynamic>> getCustomerWorkspace(String customerId) =>
      ApiService.getAgentCustomerWorkspace(customerId);

  Future<Map<String, dynamic>> getCurrentProfile() =>
      ApiService.getAgentCurrentProfile();

  Future<Map<String, dynamic>> updateCurrentProfile(
    Map<String, dynamic> payload,
  ) =>
      ApiService.updateAgentCurrentProfile(payload);

  Future<List<Map<String, dynamic>>> searchCustomers({
    String? mobile,
    String? name,
    String? aadhaar,
    String? membership,
  }) => ApiService.searchCustomers(
        mobile: mobile,
        name: name,
        aadhaar: aadhaar,
        membership: membership,
      );

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> payload) =>
      ApiService.createCustomer(payload);

  Future<Map<String, dynamic>> updateCustomer(
    String customerId,
    Map<String, dynamic> payload,
  ) => ApiService.updateCustomer(customerId, payload);

  Future<Map<String, dynamic>> createFollowUpActivity({
    required String customerId,
    required String activityType,
    required String notes,
  }) => ApiService.createCrmActivity({
        'customer_id': customerId,
        'activity_type': activityType,
        'notes': notes,
      });

  Future<Map<String, dynamic>> createFollowUpTask({
    required String customerId,
    required DateTime dueDate,
    required String notes,
  }) => ApiService.createCrmTask({
        'customer_id': customerId,
        'due_date': dueDate.toIso8601String(),
        'notes': notes,
      });

  Future<Map<String, dynamic>> updateFollowUpTask({
    required String taskId,
    required String status,
    String? notes,
  }) => ApiService.updateCrmTask(taskId, {
        'status': status,
        if (notes != null) 'notes': notes,
      });

  Future<Appointment> createAppointment({
    required String customerId,
    required String providerId,
    required String appointmentType,
    required DateTime appointmentDate,
    String? remarks,
  }) => ApiService.createInternalAppointment(
        customerId: customerId,
        providerId: providerId,
        appointmentType: appointmentType,
        appointmentDate: appointmentDate,
        remarks: remarks,
      );

  Future<Appointment> confirmAppointment(String appointmentId) =>
      ApiService.confirmInternalAppointment(appointmentId);

  Future<Appointment> cancelAppointment(String appointmentId) =>
      ApiService.cancelInternalAppointment(appointmentId);

  Future<Appointment> rescheduleAppointment({
    required String appointmentId,
    required DateTime appointmentDate,
    String? remarks,
  }) => ApiService.rescheduleInternalAppointment(
        appointmentId: appointmentId,
        appointmentDate: appointmentDate,
        remarks: remarks,
      );

  Future<Document> uploadCustomerDocument({
    required String customerId,
    required String fileName,
    required String documentType,
    required Uint8List fileBytes,
    required String mimeType,
    required int fileSize,
  }) => ApiService.uploadScopedCustomerDocument(
        customerId: customerId,
        fileName: fileName,
        documentType: documentType,
        fileBytes: fileBytes,
        mimeType: mimeType,
        fileSize: fileSize,
      );

  Future<void> markNotificationRead(String notificationId) =>
      ApiService.markNotificationRead(notificationId);

  Future<Map<String, dynamic>> markAllNotificationsRead({String? customerId}) =>
      ApiService.markAllNotificationsRead(customerId: customerId);

  Future<List<Map<String, dynamic>>> getProviders() => ApiService.getProviders();

  Future<List<Map<String, dynamic>>> getBusinesses() => ApiService.getBusinesses();

  Future<List<Map<String, dynamic>>> getMembershipTypes() =>
      ApiService.getMasterDataDomain('membership-types');
}
