import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'prescription_file_picker.dart';

Future<PickedPrescriptionFile?> pickPrescriptionFile() async {
  final picked = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    withData: true,
  );

  if (picked == null || picked.files.isEmpty) {
    return null;
  }

  final selectedFile = picked.files.first;
  final fileName = selectedFile.name.trim();
  final fileBytes =
      selectedFile.bytes ??
      (selectedFile.path == null
          ? null
          : await File(selectedFile.path!).readAsBytes());

  if (fileBytes == null || fileBytes.isEmpty) {
    return null;
  }

  return PickedPrescriptionFile(
    name: fileName.isEmpty ? 'prescription.pdf' : fileName,
    size: selectedFile.size,
    mimeType: selectedFile.extension == null
        ? null
        : _inferMimeType(selectedFile.extension!),
    bytes: fileBytes,
  );
}

String _inferMimeType(String extension) {
  switch (extension.toLowerCase()) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    default:
      return 'application/pdf';
  }
}
