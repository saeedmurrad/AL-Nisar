import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryImageModel {
  const GalleryImageModel({
    required this.id,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedAt,
    required this.isActive,
  });

  final String id;
  final String storagePath;
  final String downloadUrl;
  final DateTime uploadedAt;
  final bool isActive;

  Map<String, dynamic> toMap() => {
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'isActive': isActive,
      };

  factory GalleryImageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    final ts = d['uploadedAt'];
    return GalleryImageModel(
      id: doc.id,
      storagePath: (d['storagePath'] as String?) ?? '',
      downloadUrl: (d['downloadUrl'] as String?) ?? '',
      uploadedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      isActive: (d['isActive'] as bool?) ?? true,
    );
  }
}

