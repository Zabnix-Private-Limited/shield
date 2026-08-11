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

  String get cardStatus => membership?.cardStatus?.trim().toUpperCase() ?? '';

  bool get hasIssuedMembershipCard =>
      isCustomerActive &&
      (membership?.isActive ?? false) &&
      (cardStatus == 'ISSUED' || cardStatus == 'ACTIVE');

  bool get serviceAccessEnabled => hasIssuedMembershipCard;

  String get membershipStatus =>
      membership?.membershipStatus.trim().toUpperCase() ?? 'NO_MEMBERSHIP';

  bool get isExpired => membershipStatus == 'EXPIRED';
  bool get isSuspended => membershipStatus == 'SUSPENDED';

  String get heroStatusLabel => serviceAccessEnabled
      ? 'ACTIVE'
      : membership?.isActive ?? false
      ? 'CARD PENDING'
      : membershipStatus;

  String get membershipHeadline => serviceAccessEnabled
      ? membership?.tierLabel ?? 'SHIELD Member'
      : membership?.isActive ?? false
      ? 'Membership active'
      : isExpired
      ? 'Membership expired'
      : isSuspended
      ? 'Membership suspended'
      : 'Membership pending';

  String get membershipSupportingText => serviceAccessEnabled
      ? 'Issued by SHIELD admin or agent team'
      : membership?.isActive ?? false
      ? 'Your membership is active. Card issuance is pending before care services can be used.'
      : isExpired
      ? 'Your membership has expired. Renewal is unavailable until a verified payment workflow is provided.'
      : isSuspended
      ? 'Your membership is suspended. Contact SHIELD support for assistance.'
      : 'Registration complete. Awaiting admin or agent approval and card issuance.';

  String get walletStatusLabel => serviceAccessEnabled ? 'ACTIVE' : 'LOCKED';

  String get servicesStatusLabel =>
      serviceAccessEnabled ? 'AVAILABLE' : 'BROWSE ONLY';
}
