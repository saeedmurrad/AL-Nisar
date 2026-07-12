import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/book_reader_args.dart';
import '../models/book_model.dart';
import '../models/bookmark_model.dart';
import '../services/book_service.dart';
import '../services/bookmark_service.dart';
import '../services/pdf_cache_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/book_feature_icons.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/islamic_ui.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _bookmarkService = BookmarkService();
  final _bookService = BookService();
  final _cache = PdfCacheService();

  Future<List<BookmarkModel>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _bookmarkService.getAllBookmarks();
    });
  }

  Map<String, List<BookmarkModel>> _groupByBook(List<BookmarkModel> all) {
    final map = <String, List<BookmarkModel>>{};
    for (final b in all) {
      map.putIfAbsent(b.bookId, () => []).add(b);
    }
    for (final e in map.entries) {
      e.value.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    }
    return map;
  }

  Future<void> _openReader(BookmarkModel bm) async {
    final book = await _bookService.getBookById(bm.bookId);
    if (!mounted) return;
    if (book == null) {
      final cached = await _cache.isPdfCached(bm.bookId);
      if (!mounted) return;
      if (!cached) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This book is not available right now.',
              style: AppTheme.lato(color: context.c.textPrimary),
            ),
            backgroundColor: context.c.backgroundElevated,
          ),
        );
        return;
      }

      // Firestore entry may be missing/blocked, but cached PDF can still be read.
      final fallback = BookModel(
        id: bm.bookId,
        title: bm.bookTitle.isNotEmpty ? bm.bookTitle : 'Book',
        titleUrdu: '',
        author: '',
        category: 'Books',
        description: '',
        storagePath: bm.bookStoragePath ?? '',
        coverImageUrl: '',
        totalPages: 0,
        uploadedAt: DateTime.now(),
        isActive: true,
      );
      context.push(
        '/books/reader',
        extra: BookReaderArgs(book: fallback, initialPage: bm.pageNumber),
      );
      return;
    }
    context.push(
      '/books/reader',
      extra: BookReaderArgs(book: book, initialPage: bm.pageNumber),
    );
  }

  Future<void> _confirmDelete(BookmarkModel bm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.c;
        return AlertDialog(
          backgroundColor: c.backgroundSurface,
          title: Text(
            'Remove bookmark?',
            style: AppTheme.cormorantGaramond(color: c.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: AppTheme.lato(color: c.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Remove', style: AppTheme.lato(color: c.accentGold)),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await _bookmarkService.removeBookmark(bm.bookId, bm.pageNumber);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StandardShellHeader(
            padding: const EdgeInsets.fromLTRB(4, 12, 16, 14),
            titleWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Bookmarks',
                  style: AppTheme.cormorantGaramond(
                    fontSize: 22,
                    color: kOnEmeraldColors.textPrimary,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    'میرے نشانات',
                    style: AppTheme.amiriUrdu(
                      fontSize: 15,
                      height: 1.3,
                      color: kOnEmeraldColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            trailing: FutureBuilder<List<BookmarkModel>>(
              future: _future,
              builder: (context, snap) {
                final n = snap.data?.length ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kOnEmeraldColors.accentGold.o(0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: kOnEmeraldColors.accentGold.o(0.5)),
                  ),
                  child: Text(
                    '$n bookmarks',
                    style: AppTheme.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kOnEmeraldColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ContentColumn(
              child: FutureBuilder<List<BookmarkModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: c.accentGold),
                  );
                }
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const BookmarkBookGoldIcon(size: 72),
                          const SizedBox(height: 20),
                          Text(
                            'No bookmarks yet',
                            style: AppTheme.cormorantGaramond(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the bookmark icon while reading to save pages',
                            textAlign: TextAlign.center,
                            style: AppTheme.lato(
                              fontSize: 14,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final grouped = _groupByBook(list);
                final bookIds = grouped.keys.toList();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: bookIds.length,
                  itemBuilder: (context, i) {
                    final id = bookIds[i];
                    final items = grouped[id]!;
                    final title = items.first.bookTitle.isNotEmpty
                        ? items.first.bookTitle
                        : 'Book';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (i > 0) const SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.only(
                            top: i > 0 ? 12 : 0,
                            bottom: 8,
                          ),
                          decoration: BoxDecoration(
                            border: i > 0
                                ? Border(
                                    top: BorderSide(
                                      color: c.accentGold.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 0.8,
                                    ),
                                  )
                                : null,
                          ),
                          child: Text(
                            title,
                            style: AppTheme.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: c.accentGold,
                            ),
                          ),
                        ),
                        ...items.map((bm) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openReader(bm),
                              onLongPress: () => _confirmDelete(bm),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.accentGold,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Page ${bm.pageNumber}',
                                        style: AppTheme.lato(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? c.backgroundPrimary
                                              : c.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (bm.note.isNotEmpty)
                                            Text(
                                              bm.note,
                                              style:
                                                  AppTheme.lato(
                                                    fontSize: 13,
                                                    color: c.textMuted,
                                                  ).copyWith(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(bm.savedAt),
                                            style: AppTheme.lato(
                                              fontSize: 10,
                                              color: c.textFaint,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
