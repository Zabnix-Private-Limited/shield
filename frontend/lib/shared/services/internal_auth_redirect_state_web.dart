// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

const String _pendingInternalAuthRedirectKey =
    'shield.pendingInternalAuthRedirect';

bool hasPendingInternalAuthRedirect() {
  return html.window.sessionStorage[_pendingInternalAuthRedirectKey] == '1';
}

void markPendingInternalAuthRedirect() {
  html.window.sessionStorage[_pendingInternalAuthRedirectKey] = '1';
}

void clearPendingInternalAuthRedirect() {
  html.window.sessionStorage.remove(_pendingInternalAuthRedirectKey);
}
