import 'package:cloud_firestore/cloud_firestore.dart';

/// Metadata for an Asbaq-e-Tareeqat PDF.
///
/// PDF bytes live in Firebase Storage at [storagePath].
class AsbaqPdfModel {
  const AsbaqPdfModel({
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.storagePath,
    required this.thumbnailUrl,
    required this.uploadedAt,
    required this.isActive,
  });

  final String id;
  final String titleEn;
  final String titleUr;
  final String storagePath;
  final String thumbnailUrl;
  final DateTime uploadedAt;
  final bool isActive;

  factory AsbaqPdfModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime uploadedAt = DateTime.now();
    final ts = data['uploadedAt'];
    if (ts is Timestamp) uploadedAt = ts.toDate();
    return AsbaqPdfModel(
      id: doc.id,
      titleEn: data['titleEn'] as String? ?? '',
      titleUr: data['titleUr'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      uploadedAt: uploadedAt,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'titleEn': titleEn,
        'titleUr': titleUr,
        'storagePath': storagePath,
        'thumbnailUrl': thumbnailUrl,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'isActive': isActive,
      };
}

