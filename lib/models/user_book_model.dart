class UserBookModel {
  const UserBookModel({
    required this.id,
    required this.title,
    required this.titleUrdu,
    required this.author,
    required this.category,
    required this.description,
    required this.totalPages,
    required this.addedAtMs,
  });

  final String id;
  final String title;
  final String titleUrdu;
  final String author;
  final String category;
  final String description;
  final int totalPages;
  final int addedAtMs;

  factory UserBookModel.fromJson(Map<String, dynamic> json) {
    return UserBookModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      titleUrdu: (json['titleUrdu'] as String?) ?? '',
      author: (json['author'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      addedAtMs: (json['addedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titleUrdu': titleUrdu,
      'author': author,
      'category': category,
      'description': description,
      'totalPages': totalPages,
      'addedAtMs': addedAtMs,
    };
  }
}

