import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/shield_role.dart';
import '../../../../shared/services/api_service.dart';

class CustomerVisitsRepository {
  Future<List<Appointment>> list() =>
      ApiService.getAppointments(SHIELDRole.customer);
  Future<Appointment> cancel(String id) =>
      ApiService.cancelCustomerAppointment(id);
  Future<Appointment> reschedule({
    required String id,
    required DateTime value,
  }) => ApiService.rescheduleCustomerAppointment(
    appointmentId: id,
    appointmentDate: value,
  );
}
