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
      (cardStatus == 'ISSUED' ||
          cardStatus == 'ACTIVE' ||
          cardStatus.isEmpty ||
          cardStatus == 'PENDING');

  bool get serviceAccessEnabled =>
      isCustomerActive && (membership?.isActive ?? false);

  String get membershipStatus =>
      membership?.membershipStatus.trim().toUpperCase() ?? 'NO_MEMBERSHIP';

  bool get isExpired => membershipStatus == 'EXPIRED';
  bool get isSuspended => membershipStatus == 'SUSPENDED';

  String get heroStatusLabel =>
      (serviceAccessEnabled || (membership?.isActive ?? false))
          ? 'ACTIVE'
          : membershipStatus;

  String get membershipHeadline =>
      (serviceAccessEnabled || (membership?.isActive ?? false))
          ? membership?.tierLabel ?? 'SHIELD Member'
          : isExpired
          ? 'Membership expired'
          : isSuspended
          ? 'Membership suspended'
          : 'Membership pending';

  String get membershipSupportingText =>
      (serviceAccessEnabled || (membership?.isActive ?? false))
          ? 'Active SHIELD Member'
          : isExpired
          ? 'Your membership has expired. Renewal is unavailable until a verified payment workflow is provided.'
          : isSuspended
          ? 'Your membership is suspended. Contact SHIELD support for assistance.'
          : 'Registration complete. Awaiting admin or agent approval.';

  String get walletStatusLabel => serviceAccessEnabled ? 'ACTIVE' : 'LOCKED';

  String get servicesStatusLabel =>
      serviceAccessEnabled ? 'AVAILABLE' : 'BROWSE ONLY';
}
