import 'package:cloud_firestore/cloud_firestore.dart';

import 'gallery_folder.dart';

class GalleryImageModel {
  const GalleryImageModel({
    required this.id,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedAt,
    required this.isActive,
    this.folder = 'general',
  });

  final String id;
  final String storagePath;
  final String downloadUrl;
  final DateTime uploadedAt;
  final bool isActive;
  final String folder;

  GalleryFolder get folderInfo => GalleryFolder.fromId(folder);

  bool get showInGallery =>
      isActive &&
      downloadUrl.isNotEmpty &&
      folderInfo.showInGallery;

  Map<String, dynamic> toMap() => {
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'isActive': isActive,
        'folder': GalleryFolder.normalizeId(folder),
      };

  GalleryImageModel copyWith({
    String? folder,
    bool? isActive,
  }) {
    return GalleryImageModel(
      id: id,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      uploadedAt: uploadedAt,
      isActive: isActive ?? this.isActive,
      folder: folder ?? this.folder,
    );
  }

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
      folder: GalleryFolder.normalizeId(d['folder'] as String?),
    );
  }
}
