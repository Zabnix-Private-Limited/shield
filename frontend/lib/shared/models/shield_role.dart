enum SHIELDRole {
  customer('customer', 'Customer'),
  pharmacyStaff('pharmacy-staff', 'Pharmacy Staff'),
  clinicStaff('clinic-staff', 'Clinic Staff'),
  dentalStaff('dental-staff', 'Dental Staff'),
  crmExecutive('crm-executive', 'CRM Executive'),
  shieldExecutive('shield-executive', 'SHIELD Executive'),
  manager('manager', 'Manager'),
  superAdmin('super-admin', 'Super Admin');

  final String routeKey;
  final String label;

  const SHIELDRole(this.routeKey, this.label);

  static SHIELDRole fromRouteKey(String? value) {
    return SHIELDRole.values.firstWhere(
      (role) => role.routeKey == value,
      orElse: () => SHIELDRole.customer,
    );
  }
}
