class SabaqModel {
  const SabaqModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.pageCount,
    required this.coverImageUrl,
    required this.isLocked,
    required this.pages,
    this.urduTitle,
    this.lessonNumber,
  });

  final String id;
  final String title;
  final String subtitle;
  final int pageCount;
  final String coverImageUrl;
  final bool isLocked;
  final List<SabaqPage> pages;
  final String? urduTitle;
  final int? lessonNumber;
}

class SabaqPage {
  const SabaqPage({
    required this.chapterTitle,
    required this.urdu,
    required this.english,
  });

  final String chapterTitle;
  final String urdu;
  final String english;
}
