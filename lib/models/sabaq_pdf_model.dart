import 'package:cloud_firestore/cloud_firestore.dart';

/// Metadata for a Sabaq PDF.
///
/// PDF bytes live in Firebase Storage at [storagePath].
class SabaqPdfModel {
  const SabaqPdfModel({
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.storagePath,
    required this.thumbnailUrl,
    required this.uploadedAt,
    required this.isActive,
    this.orderNumber,
  });

  final String id;
  final String titleEn;
  final String titleUr;
  final String storagePath;
  final String thumbnailUrl;
  final DateTime uploadedAt;
  final bool isActive;
  final int? orderNumber;

  factory SabaqPdfModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime uploadedAt = DateTime.now();
    final ts = data['uploadedAt'];
    if (ts is Timestamp) uploadedAt = ts.toDate();
    return SabaqPdfModel(
      id: doc.id,
      titleEn: data['titleEn'] as String? ?? '',
      titleUr: data['titleUr'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      uploadedAt: uploadedAt,
      isActive: data['isActive'] as bool? ?? true,
      orderNumber: (data['orderNumber'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'titleEn': titleEn,
        'titleUr': titleUr,
        'storagePath': storagePath,
        'thumbnailUrl': thumbnailUrl,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'isActive': isActive,
        if (orderNumber != null) 'orderNumber': orderNumber,
      };
}
