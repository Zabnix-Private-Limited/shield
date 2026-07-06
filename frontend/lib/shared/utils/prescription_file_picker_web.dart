// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'prescription_file_picker.dart';

Future<PickedPrescriptionFile?> pickPrescriptionFile() async {
  final completer = Completer<PickedPrescriptionFile?>();
  final input = html.FileUploadInputElement()..accept = '.pdf,.png,.jpg,.jpeg';

  input.onChange.listen((_) async {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return;
    }

    final bytes = await _readBytes(file);
    if (bytes == null || bytes.isEmpty) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return;
    }

    if (!completer.isCompleted) {
      completer.complete(
        PickedPrescriptionFile(
          name: file.name,
          size: file.size,
          mimeType: file.type.isEmpty ? null : file.type,
          bytes: bytes,
        ),
      );
    }
  });

  input.click();
  return completer.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () => null,
  );
}

Future<Uint8List?> _readBytes(html.File file) {
  final completer = Completer<Uint8List?>();
  final reader = html.FileReader();

  reader.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });

  reader.onLoadEnd.listen((_) {
    final result = reader.result;
    if (!completer.isCompleted) {
      if (result is Uint8List) {
        completer.complete(result);
      } else if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else {
        completer.complete(null);
      }
    }
  });

  reader.readAsArrayBuffer(file);
  return completer.future;
}
