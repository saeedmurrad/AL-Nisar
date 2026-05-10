import 'package:cloud_firestore/cloud_firestore.dart';

class SabaqAccessRequestModel {
  const SabaqAccessRequestModel({
    required this.id,
    required this.userId,
    required this.sabaqId,
    required this.status,
    required this.createdAt,
    required this.titleEn,
    required this.titleUr,
    required this.userEmail,
    required this.userName,
  });

  final String id;
  final String userId;
  final String sabaqId;
  final String status; // pending | approved | denied
  final DateTime createdAt;
  final String titleEn;
  final String titleUr;
  final String userEmail;
  final String userName;

  factory SabaqAccessRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    DateTime createdAt = DateTime.now();
    final ts = data['createdAt'];
    if (ts is Timestamp) createdAt = ts.toDate();
    return SabaqAccessRequestModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      sabaqId: data['sabaqId'] as String? ?? '',
      status: (data['status'] as String? ?? 'pending').toLowerCase(),
      createdAt: createdAt,
      titleEn: data['titleEn'] as String? ?? '',
      titleUr: data['titleUr'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
    );
  }
}
