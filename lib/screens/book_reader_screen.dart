import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';

import '../navigation/go_router_helpers.dart';
import '../models/book_reader_args.dart';
import '../services/book_service.dart';
import '../services/bookmark_service.dart';
import '../services/pdf_cache_service.dart';
import '../services/reading_progress_service.dart';
import '../services/share_page_image_helper.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../utils/file_bytes_utils.dart';
import '../widgets/pdf_nav_controls.dart';

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({super.key, required this.args});

  final BookReaderArgs args;

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final _pdf = PdfViewerController();
  final _cache = PdfCacheService();
  final _bookmarks = BookmarkService();
  final _progress = ReadingProgressService();
  final _searchField = TextEditingController();
  final _viewerBoundaryKey = GlobalKey();
  final _books = BookService();

  Uint8List? _pdfBytes;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _loading = true;
  bool _loadFailed = false;
  double? _downloadProgress;
  bool _barsVisible = true;
  Timer? _hideTimer;
  bool _searchOpen = false;
  PdfTextSearchResult? _searchResult;
  double _zoomLevel = 1.0;
  bool? _pageBookmarked;
  Timer? _saveProgressTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadFile();
    _touchBars();
  }

  Future<void> _loadFile() async {
    final book = widget.args.book;
    final cachedBytes = await _cache.getCachedPdfBytes(book.id);
    if (!mounted) return;
    if (cachedBytes == null) {
      if (widget.args.autoDownloadIfMissing &&
          book.storagePath.trim().isNotEmpty) {
        try {
          setState(() => _downloadProgress = 0);
          final url = await _books.getBookDownloadUrl(book.storagePath);
          final out = await _cache.downloadAndCachePdf(book.id, url, (p) {
            if (mounted) setState(() => _downloadProgress = p);
          });
          if (!mounted) return;
          setState(() {
            _pdfBytes = out;
            _loading = false;
            _loadFailed = false;
            _downloadProgress = null;
          });
          return;
        } catch (_) {
          // fall through to error UI
        }
      }
      setState(() {
        _loading = false;
        _loadFailed = true;
        _downloadProgress = null;
      });
      return;
    }
    setState(() {
      _pdfBytes = cachedBytes;
      _loading = false;
    });
  }

  void _touchBars() {
    _hideTimer?.cancel();
    setState(() => _barsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_searchOpen) {
        setState(() => _barsVisible = false);
      }
    });
  }

  Future<void> _refreshBookmarkState() async {
    final b = await _bookmarks.isPageBookmarked(
      widget.args.book.id,
      _currentPage,
    );
    if (mounted) setState(() => _pageBookmarked = b);
  }

  void _scheduleSaveProgress() {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = Timer(const Duration(milliseconds: 400), () {
      _progress.setLastPage(widget.args.book.id, _currentPage);
    });
  }

  Future<void> _maybeContinuePrompt(int total) async {
    if (widget.args.initialPage != null) return;
    final last = await _progress.getLastPage(widget.args.book.id);
    if (!mounted || last == null || last <= 1 || last > total) return;
    final choice = await showDialog<_ResumeChoice>(
      context: context,
      builder: (ctx) {
        final c = ctx.c;
        return AlertDialog(
          backgroundColor: c.backgroundSurface,
          title: Text(
            'Continue from page $last?',
            style: AppTheme.cormorantGaramond(color: c.textPrimary),
          ),
          content: Text(
            'Resume where you left off or start from the beginning.',
            style: AppTheme.lato(color: c.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, _ResumeChoice.startOver),
              child: Text(
                'Start over',
                style: AppTheme.lato(color: c.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, _ResumeChoice.yes),
              child: Text('Yes', style: AppTheme.lato(color: c.accentGold)),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (choice == _ResumeChoice.startOver) {
      await _progress.clearLastPage(widget.args.book.id);
    } else if (choice == _ResumeChoice.yes) {
      _pdf.jumpToPage(last);
    }
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    _totalPages = details.document.pages.count;
    if (_totalPages < 1) _totalPages = 1;
    final initial = widget.args.initialPage;
    if (initial != null && initial >= 1 && initial <= _totalPages) {
      _pdf.jumpToPage(initial);
      _currentPage = initial;
    } else {
      _maybeContinuePrompt(_totalPages);
    }
    _refreshBookmarkState();
  }

  void _onPageChanged(PdfPageChangedDetails d) {
    setState(() => _currentPage = d.newPageNumber);
    _scheduleSaveProgress();
    _refreshBookmarkState();
  }

  Future<void> _toggleBookmark() async {
    final book = widget.args.book;
    final page = _currentPage;
    _touchBars();
    if (_pageBookmarked != true) {
      final noteController = TextEditingController();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.c.backgroundSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          final c = ctx.c;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bookmark Page $page',
                  style: AppTheme.cormorantGaramond(
                    fontSize: 20,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  style: AppTheme.lato(color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a note... (optional)',
                    hintStyle: AppTheme.lato(color: c.textFaint),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.borderDefault),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _bookmarks.addBookmark(
                      book.id,
                      page,
                      noteController.text.trim(),
                      bookTitle: book.title,
                      bookStoragePath: book.storagePath.isEmpty
                          ? null
                          : book.storagePath,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      setState(() => _pageBookmarked = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Page $page bookmarked',
                            style: AppTheme.lato(color: context.c.textPrimary),
                          ),
                          backgroundColor: context.c.backgroundElevated,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accentGold,
                    foregroundColor: Theme.of(ctx).brightness == Brightness.dark
                        ? c.backgroundPrimary
                        : c.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Bookmark',
                    style: AppTheme.lato(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    } else {
      final existing = await _bookmarks.getBookmark(book.id, page);
      if (!mounted) return;
      final sheetBg = context.c.backgroundSurface;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: sheetBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          final c = ctx.c;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Page $page is bookmarked',
                  style: AppTheme.cormorantGaramond(
                    fontSize: 20,
                    color: c.textPrimary,
                  ),
                ),
                if (existing != null && existing.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    existing.note,
                    style: AppTheme.lato(
                      fontSize: 14,
                      color: c.textMuted,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    await _bookmarks.removeBookmark(book.id, page);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      setState(() => _pageBookmarked = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Bookmark removed',
                            style: AppTheme.lato(color: context.c.textPrimary),
                          ),
                          backgroundColor: context.c.backgroundElevated,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade300,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Remove Bookmark',
                    style: AppTheme.lato(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _sharePage() async {
    final book = widget.args.book;
    final c = context.c;

    // Hide bars so the shared image is clean.
    final wasBarsVisible = _barsVisible;
    if (mounted) setState(() => _barsVisible = false);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await WidgetsBinding.instance.endOfFrame;

    try {
      final bytes = await _captureViewerToBytes();
      if (!mounted) return;
      if (bytes != null) {
        final filename =
            'al_nisar_${book.id}_p${_currentPage}_${DateTime.now().millisecondsSinceEpoch}.png';
        await Share.shareXFiles([
          xFileFromBytes(bytes, name: filename, mimeType: 'image/png'),
        ], text: 'From "${book.title}" — Page $_currentPage\nAL Nisar App');
        return;
      }
    } catch (_) {
      // Fall back below.
    } finally {
      if (mounted) setState(() => _barsVisible = wasBarsVisible);
    }

    // Fallback (always works): branded card.
    await sharePageImageCard(
      bookTitle: book.title,
      pageNumber: _currentPage,
      accentGold: c.accentGold,
      backgroundColor: c.backgroundPrimary,
      textColor: c.textPrimary,
    );
  }

  Future<Uint8List?> _captureViewerToBytes() async {
    final ctx = _viewerBoundaryKey.currentContext;
    if (ctx == null) return null;
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final pr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final image = await boundary.toImage(pixelRatio: pr.clamp(1.5, 3.0));
    final bd = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) return null;

    return bd.buffer.asUint8List();
  }

  Future<void> _showPageDialog() async {
    final controller = TextEditingController(text: '$_currentPage');
    final ok = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final c = ctx.c;
        return AlertDialog(
          backgroundColor: c.backgroundSurface,
          title: Text(
            'Go to page',
            style: AppTheme.cormorantGaramond(color: c.textPrimary),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTheme.lato(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: '1 — $_totalPages',
              hintStyle: AppTheme.lato(color: c.textFaint),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTheme.lato(color: c.textMuted)),
            ),
            TextButton(
              onPressed: () {
                final v = int.tryParse(controller.text.trim());
                Navigator.pop(ctx, v);
              },
              child: Text('Go', style: AppTheme.lato(color: c.accentGold)),
            ),
          ],
        );
      },
    );
    if (ok != null && ok >= 1 && ok <= _totalPages) {
      _pdf.jumpToPage(ok);
    }
  }

  void _openMore() {
    final book = widget.args.book;
    _touchBars();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.c.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final c = ctx.c;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.share, color: c.accentGold),
                title: Text(
                  'Share this Page',
                  style: AppTheme.lato(color: c.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _sharePage();
                },
              ),
              ListTile(
                leading: Icon(Icons.numbers, color: c.accentGold),
                title: Text(
                  'Go to Page',
                  style: AppTheme.lato(color: c.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPageDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.bookmarks_outlined, color: c.accentGold),
                title: Text(
                  'All Bookmarks',
                  style: AppTheme.lato(color: c.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/bookmarks');
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: c.accentGold),
                title: Text(
                  'Book Details',
                  style: AppTheme.lato(color: c.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/books/detail', extra: book);
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'Text size',
                  style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _zoomLevel = 0.85;
                        _pdf.zoomLevel = _zoomLevel;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Small',
                      style: AppTheme.lato(color: c.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _zoomLevel = 1.0;
                        _pdf.zoomLevel = _zoomLevel;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Medium',
                      style: AppTheme.lato(color: c.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _zoomLevel = 1.25;
                        _pdf.zoomLevel = _zoomLevel;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Large',
                      style: AppTheme.lato(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _runSearch(String query) {
    _searchResult?.removeListener(_onSearchTick);
    _searchResult = _pdf.searchText(query);
    _searchResult!.addListener(_onSearchTick);
    setState(() {});
  }

  void _onSearchTick() {
    if (mounted) setState(() {});
  }

  void _closeSearch() {
    _searchResult?.removeListener(_onSearchTick);
    _searchResult?.clear();
    _searchField.clear();
    setState(() => _searchOpen = false);
    _touchBars();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveProgressTimer?.cancel();
    _searchResult?.removeListener(_onSearchTick);
    _searchField.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final book = widget.args.book;
    // Urdu (Arabic-script) books read right-to-left; page-turn direction and
    // the viewer layout follow suit.
    final isRtl = isRtlText(book.titleUrdu) || isRtlText(book.title);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.backgroundPrimary,
        body: Center(
          child: _downloadProgress == null
              ? CircularProgressIndicator(color: c.accentGold)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Downloading PDF…',
                        style: AppTheme.lato(color: c.textMuted),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _downloadProgress,
                          minHeight: 7,
                          backgroundColor: c.backgroundElevated,
                          color: c.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    if (_loadFailed || _pdfBytes == null) {
      return Scaffold(
        backgroundColor: c.backgroundPrimary,
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
                  'This book is not on your device.',
                  style: AppTheme.cormorantGaramond(
                    fontSize: 20,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Download the book from its detail screen while online.',
                  style: AppTheme.lato(fontSize: 14, color: c.textMuted),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final search = _searchResult;
    final searchIndex = search?.currentInstanceIndex ?? 0;
    final searchTotal = search?.totalInstanceCount ?? 0;
    final searchDone = search?.isSearchCompleted ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _touchBars,
      child: Scaffold(
        backgroundColor: c.backgroundPrimary,
        body: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                key: _viewerBoundaryKey,
                child: SfPdfViewerTheme(
                  data: SfPdfViewerThemeData(
                    backgroundColor: c.backgroundPrimary,
                    progressBarColor: c.accentGold,
                  ),
                  child: Directionality(
                    textDirection: isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: SfPdfViewer.memory(
                      _pdfBytes!,
                      controller: _pdf,
                      scrollDirection: PdfScrollDirection.horizontal,
                      pageLayoutMode: PdfPageLayoutMode.single,
                      enableTextSelection: true,
                      canShowScrollHead: true,
                      canShowScrollStatus: true,
                      initialZoomLevel: _zoomLevel,
                      currentSearchTextHighlightColor: c.accentGold.withValues(
                        alpha: 0.45,
                      ),
                      otherSearchTextHighlightColor: c.accentGold.withValues(
                        alpha: 0.22,
                      ),
                      onDocumentLoaded: _onDocumentLoaded,
                      onPageChanged: _onPageChanged,
                    ),
                  ),
                ),
              ),
            ),
            // Left / right page-turn buttons — appear with the chrome bars and
            // follow the book's reading direction.
            if (_barsVisible && !_searchOpen)
              Positioned.fill(
                child: PdfNavControls(controller: _pdf, rtl: isRtl),
              ),
            AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              offset: _barsVisible || _searchOpen
                  ? Offset.zero
                  : const Offset(0, -1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _barsVisible || _searchOpen ? 1 : 0,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          c.backgroundPrimary.withValues(alpha: 0.95),
                          c.backgroundPrimary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: _searchOpen
                        ? Row(
                            children: [
                              IconButton(
                                onPressed: _closeSearch,
                                icon: Icon(Icons.close, color: c.accentGold),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchField,
                                  style: AppTheme.lato(color: c.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Search in PDF…',
                                    hintStyle: AppTheme.lato(
                                      color: c.textFaint,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: _runSearch,
                                ),
                              ),
                              if (search != null &&
                                  search.hasResult &&
                                  searchDone)
                                Text(
                                  '$searchIndex of $searchTotal',
                                  style: AppTheme.lato(
                                    fontSize: 12,
                                    color: c.textMuted,
                                  ),
                                ),
                              IconButton(
                                onPressed: () => search?.previousInstance(),
                                icon: Icon(
                                  Icons.navigate_before,
                                  color: c.accentGold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => search?.nextInstance(),
                                icon: Icon(
                                  Icons.navigate_next,
                                  color: c.accentGold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              IconButton(
                                onPressed: () => popOrGoHome(context),
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: c.accentGold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => goAppHome(context),
                                icon: Icon(
                                  Icons.home_outlined,
                                  color: c.accentGold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.cormorantGaramond(
                                    fontSize: 18,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _searchOpen = true;
                                    _barsVisible = true;
                                  });
                                },
                                icon: Icon(Icons.search, color: c.accentGold),
                              ),
                              IconButton(
                                onPressed: _toggleBookmark,
                                icon: Icon(
                                  _pageBookmarked == true
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: c.accentGold,
                                ),
                              ),
                              IconButton(
                                onPressed: _openMore,
                                icon: Icon(
                                  Icons.more_horiz,
                                  color: c.accentGold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              offset: _barsVisible && !_searchOpen
                  ? Offset.zero
                  : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _barsVisible && !_searchOpen ? 1 : 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            c.backgroundPrimary.withValues(alpha: 0.95),
                            c.backgroundPrimary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _showPageDialog,
                            child: Text(
                              'Page $_currentPage of $_totalPages',
                              style: AppTheme.lato(
                                fontSize: 13,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: c.accentGold,
                              inactiveTrackColor: c.borderDefault,
                              thumbColor: c.accentGold,
                            ),
                            child: Slider(
                              min: 1,
                              max: _totalPages.toDouble(),
                              divisions: _totalPages > 1
                                  ? _totalPages - 1
                                  : null,
                              value: _currentPage
                                  .clamp(1, _totalPages)
                                  .toDouble(),
                              onChanged: (v) {
                                _pdf.jumpToPage(v.round());
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ResumeChoice { yes, startOver }
