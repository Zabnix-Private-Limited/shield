typedef PlatformRealtimeEventHandler =
    void Function(Map<String, dynamic> event);
typedef PlatformRealtimeErrorHandler = void Function(Object error);

class PlatformRealtimeSubscription {
  const PlatformRealtimeSubscription();

  void dispose() {}
}

PlatformRealtimeSubscription connectPlatformRealtimeStream({
  required String baseUrl,
  required String workspace,
  required String accessToken,
  String? customerId,
  required PlatformRealtimeEventHandler onEvent,
  PlatformRealtimeErrorHandler? onError,
}) {
  return const PlatformRealtimeSubscription();
}
