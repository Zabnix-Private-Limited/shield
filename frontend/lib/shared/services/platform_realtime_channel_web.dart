// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

typedef PlatformRealtimeEventHandler = void Function(Map<String, dynamic> event);
typedef PlatformRealtimeErrorHandler = void Function(Object error);

class PlatformRealtimeSubscription {
  PlatformRealtimeSubscription(this._source);

  final html.EventSource _source;

  void dispose() {
    _source.close();
  }
}

PlatformRealtimeSubscription connectPlatformRealtimeStream({
  required String baseUrl,
  required String workspace,
  required String accessToken,
  String? customerId,
  required PlatformRealtimeEventHandler onEvent,
  PlatformRealtimeErrorHandler? onError,
}) {
  final uri = Uri.parse(
    '$baseUrl/platform/realtime/stream',
  ).replace(
    queryParameters: <String, String>{
      'workspace': workspace,
      'access_token': accessToken,
      if (customerId != null && customerId.trim().isNotEmpty)
        'customer_id': customerId.trim(),
    },
  );
  final source = html.EventSource(uri.toString());
  source.onMessage.listen((event) {
    try {
      final rawData = event.data;
      if (rawData == null) {
        return;
      }
      final decoded = jsonDecode(rawData.toString());
      if (decoded is Map<String, dynamic>) {
        onEvent(decoded);
      } else if (decoded is Map) {
        onEvent(Map<String, dynamic>.from(decoded));
      }
    } catch (error) {
      onError?.call(error);
    }
  });
  source.onError.listen((event) {
    onError?.call(event);
  });
  return PlatformRealtimeSubscription(source);
}
