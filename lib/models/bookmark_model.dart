class BookmarkModel {
  const BookmarkModel({
    required this.bookId,
    required this.bookTitle,
    this.bookStoragePath,
    required this.pageNumber,
    required this.note,
    required this.savedAt,
  });

  final String bookId;
  final String bookTitle;
  final String? bookStoragePath;
  final int pageNumber;
  final String note;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'bookTitle': bookTitle,
        'bookStoragePath': bookStoragePath,
        'pageNumber': pageNumber,
        'note': note,
        'savedAt': savedAt.toIso8601String(),
      };

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      bookId: json['bookId'] as String? ?? '',
      bookTitle: json['bookTitle'] as String? ?? '',
      bookStoragePath: json['bookStoragePath'] as String?,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
