enum SHIELDRole {
  customer('customer', 'Customer'),
  agent('agent', 'SHIELD Agent'),
  provider('provider', 'Provider'),
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
    switch (value) {
      case 'provider':
      case 'pharmacy-staff':
      case 'clinic-staff':
      case 'dental-staff':
        return SHIELDRole.provider;
    }

    return SHIELDRole.values.firstWhere(
      (role) => role.routeKey == value,
      orElse: () => SHIELDRole.customer,
    );
  }

  static SHIELDRole fromBackendRoleCode(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'PHARMACY_PROVIDER':
      case 'LAB_PROVIDER':
      case 'DOCTOR':
      case 'HOMECARE_PROVIDER':
      case 'DENTAL_PROVIDER':
      case 'COSMETIC_PROVIDER':
      case 'DIETITIAN':
        return SHIELDRole.provider;
      case 'CRM_EXECUTIVE':
        return SHIELDRole.crmExecutive;
      case 'SHIELD_AGENT':
        return SHIELDRole.agent;
      case 'ADMIN':
        return SHIELDRole.superAdmin;
      case 'CUSTOMER':
        return SHIELDRole.customer;
      default:
        return SHIELDRole.provider;
    }
  }

  static List<SHIELDRole> get switchableRoles => const [
    SHIELDRole.customer,
    SHIELDRole.agent,
    SHIELDRole.provider,
    SHIELDRole.crmExecutive,
    SHIELDRole.shieldExecutive,
    SHIELDRole.manager,
    SHIELDRole.superAdmin,
  ];
}
