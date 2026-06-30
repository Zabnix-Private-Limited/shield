import '../../../../../shared/models/customer.dart';
import '../../../../../shared/models/membership.dart';

class CustomerAccessState {
  const CustomerAccessState({
    this.customer,
    required this.customerStatus,
    this.membership,
  });

  final Customer? customer;
  final String customerStatus;
  final Membership? membership;

  bool get isCustomerActive => customerStatus.trim().toUpperCase() == 'ACTIVE';

  bool get hasIssuedMembershipCard =>
      isCustomerActive &&
      (membership?.isActive ?? false) &&
      ((membership?.customerCode.trim().isNotEmpty ?? false));

  bool get serviceAccessEnabled => hasIssuedMembershipCard;

  String get heroStatusLabel => serviceAccessEnabled ? 'ACTIVE' : 'PENDING';

  String get membershipHeadline =>
      serviceAccessEnabled ? membership?.tierLabel ?? 'SHIELD Member' : 'Membership pending';

  String get membershipSupportingText => serviceAccessEnabled
      ? 'Issued by SHIELD admin or agent team'
      : 'Registration complete. Awaiting admin or agent approval and card issuance.';

  String get walletStatusLabel =>
      serviceAccessEnabled ? 'ACTIVE' : 'LOCKED';

  String get servicesStatusLabel =>
      serviceAccessEnabled ? 'AVAILABLE' : 'BROWSE ONLY';
}
