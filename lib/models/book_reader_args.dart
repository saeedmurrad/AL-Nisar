import 'book_model.dart';

class BookReaderArgs {
  const BookReaderArgs({
    required this.book,
    this.initialPage,
    this.autoDownloadIfMissing = false,
  });

  final BookModel book;
  final int? initialPage;
  final bool autoDownloadIfMissing;
}
