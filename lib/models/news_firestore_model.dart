import 'package:cloud_firestore/cloud_firestore.dart';

class NewsFirestoreModel {
  const NewsFirestoreModel({
    required this.id,
    required this.title,
    required this.category,
    required this.dateLabel,
    required this.imageUrl,
    required this.readTime,
    required this.bodyParagraphs,
    required this.createdAt,
    required this.isActive,
  });

  final String id;
  final String title;
  final String category;
  final String dateLabel;
  final String imageUrl;
  final String readTime;
  final List<String> bodyParagraphs;
  final DateTime createdAt;
  final bool isActive;

  factory NewsFirestoreModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (ts is Timestamp) createdAt = ts.toDate();

    final raw = data['bodyParagraphs'];
    final body = <String>[];
    if (raw is List) {
      for (final p in raw) {
        if (p is String && p.trim().isNotEmpty) body.add(p);
      }
    }

    return NewsFirestoreModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? '',
      dateLabel: data['dateLabel'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      readTime: data['readTime'] as String? ?? '5 min read',
      bodyParagraphs: body,
      createdAt: createdAt,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'dateLabel': dateLabel,
      'imageUrl': imageUrl,
      'readTime': readTime,
      'bodyParagraphs': bodyParagraphs,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}

