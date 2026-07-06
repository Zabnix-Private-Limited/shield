// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

typedef PlatformRealtimeEventHandler =
    void Function(Map<String, dynamic> event);
typedef PlatformRealtimeErrorHandler = void Function(Object error);

class PlatformRealtimeSubscription {
  PlatformRealtimeSubscription(this._source);

  final html.EventSource _source;

  void dispose() {
    _source.close();
  }
}

void _trace(String message) {
  if (kDebugMode) {
    debugPrint('[ProviderRealtime] $message');
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
  final uri = Uri.parse('$baseUrl/platform/realtime/stream').replace(
    queryParameters: <String, String>{
      'workspace': workspace,
      'access_token': accessToken,
      if (customerId != null && customerId.trim().isNotEmpty)
        'customer_id': customerId.trim(),
    },
  );
  final tokenPreview = accessToken.length <= 12
      ? accessToken
      : '${accessToken.substring(0, 6)}...${accessToken.substring(accessToken.length - 4)}';
  _trace(
    'realtime connect requested workspace=$workspace customerId=${customerId ?? ''} token=$tokenPreview',
  );
  final source = html.EventSource(uri.toString());
  source.onOpen.listen((_) {
    _trace('realtime connected workspace=$workspace');
  });
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
    _trace('realtime failed workspace=$workspace error=$event');
    onError?.call(event);
  });
  return PlatformRealtimeSubscription(source);
}
