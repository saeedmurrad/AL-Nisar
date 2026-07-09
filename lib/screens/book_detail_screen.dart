import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../models/book_model.dart';
import '../models/bookmark_model.dart';
import '../models/book_reader_args.dart';
import '../services/book_service.dart';
import '../services/bookmark_service.dart';
import '../services/pdf_cache_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../navigation/go_router_helpers.dart';
import '../utils/connectivity_helper.dart';
import '../widgets/ornament_divider.dart';
import '../widgets/shimmer_placeholder.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, this.initialBook, this.bookId});

  final BookModel? initialBook;
  final String? bookId;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _bookService = BookService();
  final _cache = PdfCacheService();
  final _bookmarks = BookmarkService();

  BookModel? _book;
  String? _loadError;
  bool _loadingBook = true;

  double _progress = 0;
  bool _downloading = false;
  bool _cancelDownload = false;
  bool _cached = false;
  bool _offline = false;

  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    _book = widget.initialBook;
    _load();
    _connSub = Connectivity().onConnectivityChanged.listen((_) {
      _checkConn();
    });
    _checkConn();
  }

  Future<void> _checkConn() async {
    final online = await hasNetworkConnection();
    if (mounted) setState(() => _offline = !online);
  }

  Future<void> _load() async {
    if (_book != null) {
      await _refreshCachedFlag();
      setState(() => _loadingBook = false);
      return;
    }
    final id = widget.bookId;
    if (id == null || id.isEmpty) {
      setState(() {
        _loadingBook = false;
        _loadError = 'missing';
      });
      return;
    }
    try {
      final b = await _bookService.getBookById(id);
      setState(() {
        _book = b;
        _loadError = b == null ? 'missing' : null;
        _loadingBook = false;
      });
      if (b != null) await _refreshCachedFlag();
    } catch (_) {
      setState(() {
        _loadingBook = false;
        _loadError = 'failed';
      });
    }
  }

  Future<void> _refreshCachedFlag() async {
    final b = _book;
    if (b == null) return;
    final ok = await _cache.isPdfCached(b.id);
    if (mounted) setState(() => _cached = ok);
  }

  Future<void> _startDownload() async {
    final b = _book;
    if (b == null) return;
    final online = await hasNetworkConnection();
    if (!online) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connect to internet to download this book',
              style: AppTheme.lato(color: context.c.textPrimary),
            ),
            backgroundColor: context.c.backgroundElevated,
          ),
        );
      }
      return;
    }
    setState(() {
      _downloading = true;
      _cancelDownload = false;
      _progress = 0;
    });
    try {
      final url = await _bookService.getBookDownloadUrl(b.storagePath);
      await _cache.downloadAndCachePdf(b.id, url, (p) {
        if (mounted) setState(() => _progress = p);
      }, shouldContinue: () => !_cancelDownload);
      if (_cancelDownload) return;
      if (mounted) {
        setState(() {
          _downloading = false;
          _cached = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Download could not be completed. Please try again.',
              style: AppTheme.lato(color: context.c.textPrimary),
            ),
            backgroundColor: context.c.backgroundElevated,
          ),
        );
      }
    }
  }

  Future<void> _removeCache() async {
    final b = _book;
    if (b == null) return;
    await _cache.deleteCachedPdf(b.id);
    if (mounted) setState(() => _cached = false);
  }

  void _openReader({int? page}) {
    final b = _book;
    if (b == null) return;
    context.push(
      '/books/reader',
      extra: BookReaderArgs(book: b, initialPage: page),
    );
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final onGold = Theme.of(context).brightness == Brightness.dark
        ? c.backgroundPrimary
        : c.textPrimary;

    if (_loadingBook) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: c.accentGold)),
      );
    }

    if (_loadError != null || _book == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => popOrGoHome(context),
                      icon: Icon(Icons.arrow_back, color: c.accentGold),
                    ),
                    IconButton(
                      onPressed: () => goAppHome(context),
                      icon: Icon(Icons.home_outlined, color: c.accentGold),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'This book could not be opened.',
                  style: AppTheme.cormorantGaramond(
                    fontSize: 20,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your connection or try again later.',
                  style: AppTheme.lato(fontSize: 14, color: c.textMuted),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final book = _book!;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_offline && _cached)
            Material(
              color: c.accentGold.withValues(alpha: 0.12),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.offline_pin, size: 18, color: c.accentGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are offline — reading cached version',
                          style: AppTheme.lato(
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Stack(
            children: [
              SizedBox(
                height: 260,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: book.coverImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerPlaceholder(),
                  errorWidget: (context, url, error) =>
                      const GoldPatternError(),
                ),
              ),
              Container(
                height: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      c.backgroundPrimary.withValues(alpha: 0.05),
                      c.backgroundPrimary.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 16,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.accentGold.o(0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${book.totalPages} pages',
                      style: AppTheme.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? c.backgroundPrimary
                            : c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 16, 0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => popOrGoHome(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: c.backgroundElevated.o(0.75),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: c.borderDefault,
                              width: 0.5,
                            ),
                          ),
                          child: SvgPicture.string(
                            _backSvg,
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(
                              c.accentGold,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => goAppHome(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: c.backgroundElevated.o(0.75),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: c.borderDefault,
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.home_outlined,
                            size: 20,
                            color: c.accentGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: Column(
                  children: [
                    Text(
                      book.title,
                      textAlign: TextAlign.center,
                      style: AppTheme.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        book.titleUrdu,
                        textAlign: TextAlign.center,
                        style: AppTheme.amiriUrdu(
                          fontSize: 16,
                          height: 1.35,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: c.accentGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        book.author,
                        style: AppTheme.lato(
                          fontSize: 14,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.accentGold.o(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.accentGold.o(0.45)),
                    ),
                    child: Text(
                      book.category,
                      style: AppTheme.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.accentGold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  book.description,
                  style: AppTheme.lato(
                    fontSize: 15,
                    height: 1.65,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                const OrnamentDivider(),
                const SizedBox(height: 20),
                FutureBuilder<List<BookmarkModel>>(
                  future: _bookmarks.getBookmarksForBook(book.id),
                  builder: (context, snap) {
                    final list = snap.data ?? [];
                    if (list.isEmpty) return const SizedBox.shrink();
                    final recent = [...list]
                      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
                    final top = recent.take(3).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Bookmarks',
                          style: AppTheme.cormorantGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: top.map((bm) {
                            return InkWell(
                              onTap: () => _openReader(page: bm.pageNumber),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: c.accentGold.o(0.2),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: c.accentGold.o(0.5),
                                  ),
                                ),
                                child: Text(
                                  'Page ${bm.pageNumber}',
                                  style: AppTheme.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
                if (_downloading) ...[
                  Center(
                    child: CircularProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      color: c.accentGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}% downloaded',
                      style: AppTheme.lato(fontSize: 13, color: c.textMuted),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _cancelDownload = true);
                      },
                      child: Text(
                        'Cancel',
                        style: AppTheme.lato(fontSize: 13, color: c.textMuted),
                      ),
                    ),
                  ),
                ] else if (!_cached) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accentGold,
                        foregroundColor: onGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Open Book',
                        style: AppTheme.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: onGold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openReader(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accentGold,
                        foregroundColor: onGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Read Now',
                        style: AppTheme.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: onGold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _removeCache,
                      child: Text(
                        'Remove from device',
                        style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _backSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M14.5 5.5L8 12l6.5 6.5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>';
