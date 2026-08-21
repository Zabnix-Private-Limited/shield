String pharmacyFriendlyErrorMessage(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final value = error?.toString() ?? '';
  final normalized = value.toLowerCase();

  if (normalized.contains('dioexception') ||
      normalized.contains('xmlhttprequest') ||
      normalized.contains('socketexception') ||
      normalized.contains('connection error') ||
      normalized.contains('failed host lookup')) {
    return "You're offline. Check your connection and try again.";
  }
  if (normalized.contains('timeout')) {
    return 'This is taking longer than expected. Please try again.';
  }
  if (normalized.contains('401') || normalized.contains('403')) {
    return 'Your session no longer has access to this Pharmacy workspace.';
  }
  if (normalized.contains('404')) {
    return 'The requested Pharmacy record could not be found.';
  }
  if (normalized.contains('409')) {
    return 'This record changed elsewhere. Refresh and review the latest details.';
  }
  if (normalized.contains('500') ||
      normalized.contains('502') ||
      normalized.contains('503')) {
    return 'The Pharmacy service is temporarily unavailable. Please try again.';
  }
  return fallback;
}
