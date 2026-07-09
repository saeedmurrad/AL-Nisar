import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  const LessonModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.pageCount,
    required this.coverImageUrl,
    required this.isLocked,
    required this.pages,
    required this.createdAt,
    this.urduTitle,
    this.lessonNumber,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final int pageCount;
  final String coverImageUrl;
  final bool isLocked;
  final List<LessonPage> pages;
  final DateTime createdAt;
  final String? urduTitle;
  final int? lessonNumber;
  final bool isActive;

  factory LessonModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (ts is Timestamp) createdAt = ts.toDate();

    final pagesRaw = data['pages'];
    final pages = <LessonPage>[];
    if (pagesRaw is List) {
      for (final p in pagesRaw) {
        if (p is Map) {
          pages.add(LessonPage.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }

    return LessonModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      pageCount: (data['pageCount'] as num?)?.toInt() ?? pages.length,
      coverImageUrl: data['coverImageUrl'] as String? ?? '',
      isLocked: data['isLocked'] as bool? ?? false,
      pages: pages,
      createdAt: createdAt,
      urduTitle: data['urduTitle'] as String?,
      lessonNumber: (data['lessonNumber'] as num?)?.toInt(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'pageCount': pageCount,
      'coverImageUrl': coverImageUrl,
      'isLocked': isLocked,
      'pages': pages.map((p) => p.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'urduTitle': urduTitle,
      'lessonNumber': lessonNumber,
      'isActive': isActive,
    };
  }
}

class LessonPage {
  const LessonPage({
    required this.chapterTitle,
    required this.urdu,
    required this.english,
  });

  final String chapterTitle;
  final String urdu;
  final String english;

  factory LessonPage.fromJson(Map<String, dynamic> json) {
    return LessonPage(
      chapterTitle: json['chapterTitle'] as String? ?? '',
      urdu: json['urdu'] as String? ?? '',
      english: json['english'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'chapterTitle': chapterTitle, 'urdu': urdu, 'english': english};
  }
}
