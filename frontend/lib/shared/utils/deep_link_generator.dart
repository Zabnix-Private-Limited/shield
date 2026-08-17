class DeepLinkGenerator {
  static const String customScheme = 'shield';
  static const String customHost = 'app';
  static const String defaultWebDomain = 'https://shield-zabnix.vercel.app';

  static String get baseUrl => defaultWebDomain;

  /// Customer referral link: https://shield-zabnix.vercel.app/#/customer/signup?ref=CODE
  static String customerReferralWeb(String referralCode) {
    final clean = referralCode.trim();
    return '$baseUrl/#/customer/signup?ref=${Uri.encodeComponent(clean)}';
  }

  /// Custom app scheme referral link: shield://app/customer/signup?ref=CODE
  static String customerReferralApp(String referralCode) {
    final clean = referralCode.trim();
    return '$customScheme://$customHost/customer/signup?ref=${Uri.encodeComponent(clean)}';
  }

  /// Prescription upload for a specific pharmacy: https://shield-zabnix.vercel.app/#/portal/customer/prescriptions?provider=ID
  static String customerPrescriptionUpload({String? providerId}) {
    final query = providerId != null && providerId.isNotEmpty
        ? '?provider=${Uri.encodeComponent(providerId)}&type=PHARMACY'
        : '?type=PHARMACY';
    return '$baseUrl/#/portal/customer/prescriptions$query';
  }

  /// Booking appointment for a provider: https://shield-zabnix.vercel.app/#/portal/customer/book-appointment?provider=ID
  static String customerBookAppointment({
    required String providerId,
    String? type,
  }) {
    final typeParam = type != null ? '&type=${Uri.encodeComponent(type)}' : '';
    return '$baseUrl/#/portal/customer/book-appointment?provider=${Uri.encodeComponent(providerId)}$typeParam';
  }

  /// Privilege Card view: https://shield-zabnix.vercel.app/#/portal/customer/privilege-card
  static String customerPrivilegeCard() {
    return '$baseUrl/#/portal/customer/privilege-card';
  }

  /// Customer Wallet: https://shield-zabnix.vercel.app/#/portal/customer/wallet
  static String customerWallet() {
    return '$baseUrl/#/portal/customer/wallet';
  }

  /// Agent Customer Registration: https://shield-zabnix.vercel.app/#/portal/agent/registration
  static String agentRegistration() {
    return '$baseUrl/#/portal/agent/registration';
  }

  /// Provider Prescriptions Queue: https://shield-zabnix.vercel.app/#/portal/provider/prescriptions
  static String providerPrescriptions() {
    return '$baseUrl/#/portal/provider/prescriptions';
  }

  /// Parses any incoming URI (e.g., custom scheme or web URL) into a canonical internal route path for GoRouter.
  static String? normalizeToRoutePath(Uri uri) {
    if (uri.scheme == customScheme) {
      final rawPath = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      final path = rawPath.startsWith('/app') ? rawPath.substring(4) : rawPath;
      final query = uri.hasQuery ? '?${uri.query}' : '';
      return '${path.isEmpty ? '/' : path}$query';
    }

    if (uri.fragment.isNotEmpty) {
      final fragment = uri.fragment.startsWith('/')
          ? uri.fragment
          : '/${uri.fragment}';
      return fragment;
    }

    if (uri.path.isNotEmpty && uri.path != '/') {
      final path = uri.path;
      final query = uri.hasQuery ? '?${uri.query}' : '';
      return '$path$query';
    }

    return null;
  }
}
