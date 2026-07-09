import 'dart:typed_data';

class UploadFileData {
  const UploadFileData({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get length => bytes.length;

  String get lowerName => name.toLowerCase();
}
