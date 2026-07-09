import 'package:file_picker/file_picker.dart';

import '../models/upload_file_data.dart';

Future<UploadFileData?> pickUploadFile({
  required List<String> allowedExtensions,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    withData: true,
  );
  final file = result?.files.single;
  final bytes = file?.bytes;
  final name = file?.name.trim() ?? '';
  if (bytes == null || name.isEmpty) return null;
  return UploadFileData(name: name, bytes: bytes);
}

Future<List<UploadFileData>> pickMultipleUploadFiles({
  required List<String> allowedExtensions,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    allowMultiple: true,
    withData: true,
  );
  final files = result?.files ?? const <PlatformFile>[];
  return files
      .where(
        (file) =>
            (file.bytes?.isNotEmpty ?? false) && file.name.trim().isNotEmpty,
      )
      .map((file) => UploadFileData(name: file.name, bytes: file.bytes!))
      .toList();
}
