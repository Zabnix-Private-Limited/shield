// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

Future<bool> downloadPlatformFile({
  required String fileName,
  required String mimeType,
  required String contentBase64,
  bool openInline = false,
}) async {
  final bytes = base64Decode(contentBase64);
  final blob = html.Blob(<dynamic>[bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    if (openInline) {
      html.window.open(url, '_blank');
      return true;
    }
    final anchor =
        html.AnchorElement(href: url)
          ..download = fileName
          ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    return true;
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}

Future<bool> openPlatformUrl(String url) async {
  html.window.open(url, '_blank');
  return true;
}
