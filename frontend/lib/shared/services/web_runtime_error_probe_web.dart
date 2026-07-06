// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'package:flutter/foundation.dart';

bool _installed = false;

Future<void> ensureWebRuntimeErrorProbe() async {
  if (_installed) {
    return;
  }
  _installed = true;

  html.window.addEventListener('error', (event) {
    if (event is html.ErrorEvent) {
      debugPrint(
        '[WebRuntimeProbe] window.error message=${event.message} file=${event.filename} line=${event.lineno} column=${event.colno} error=${event.error}',
      );
      return;
    }
    debugPrint('[WebRuntimeProbe] window.error event=$event');
  });

  html.window.addEventListener('unhandledrejection', (event) {
    if (event is html.PromiseRejectionEvent) {
      debugPrint('[WebRuntimeProbe] unhandledrejection reason=${event.reason}');
      return;
    }
    debugPrint('[WebRuntimeProbe] unhandledrejection event=$event');
  });
}
