import 'dart:typed_data';

import 'prescription_file_picker_stub.dart'
    if (dart.library.io) 'prescription_file_picker_io.dart'
    if (dart.library.html) 'prescription_file_picker_web.dart' as impl;

class PickedPrescriptionFile {
  final String name;
  final int size;
  final String? mimeType;
  final Uint8List bytes;

  const PickedPrescriptionFile({
    required this.name,
    required this.size,
    required this.bytes,
    this.mimeType,
  });
}

Future<PickedPrescriptionFile?> pickPrescriptionFile() {
  return impl.pickPrescriptionFile();
}
