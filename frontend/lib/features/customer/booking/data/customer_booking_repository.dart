import '../../../../shared/models/appointment.dart';
import '../../../../shared/services/api_service.dart';
import '../../services/data/models/customer_provider.dart';
import '../../services/data/repositories/customer_provider_repository.dart';

class CustomerBookingRepository {
  CustomerBookingRepository({CustomerProviderRepository? providers})
    : _providers = providers ?? CustomerProviderRepository();

  final CustomerProviderRepository _providers;

  Future<CustomerProvider> provider(String id) => _providers.provider(id);

  Future<List<CustomerProvider>> findProviders({
    String? query,
    String? type,
  }) async => (await _providers.providers(query: query, type: type)).items;

  Future<Appointment> submit({
    required CustomerProvider provider,
    required DateTime preferredDateTime,
    String? notes,
  }) => ApiService.createCustomerAppointment(
    providerId: provider.id,
    appointmentType: _appointmentType(provider.type),
    appointmentDate: preferredDateTime,
    remarks: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
  );

  String _appointmentType(String providerType) {
    switch (providerType.trim().toUpperCase()) {
      case 'DENTAL':
        return 'DENTAL';
      case 'HOMECARE':
      case 'HOME_CARE':
        return 'HOME_VISIT';
      case 'LAB':
      case 'LABORATORY':
        return 'LAB';
      default:
        return 'CLINIC';
    }
  }
}
