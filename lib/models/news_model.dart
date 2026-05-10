class NewsModel {
  const NewsModel({
    required this.id,
    required this.title,
    required this.category,
    required this.dateLabel,
    required this.imageUrl,
    this.readTime = '5 min read',
    this.bodyParagraphs = const [],
  });

  final String id;
  final String title;
  final String category;
  final String dateLabel;
  final String imageUrl;
  final String readTime;
  final List<String> bodyParagraphs;
}
