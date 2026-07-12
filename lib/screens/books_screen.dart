import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/book_model.dart';
import '../models/book_reader_args.dart';
import '../providers/book_provider.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme_colors.dart';
import '../utils/connectivity_helper.dart';
import '../utils/responsive_layout.dart';
import '../widgets/book_feature_icons.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/gold_card.dart';
import '../widgets/standard_shell_header.dart';
import '../widgets/islamic_ui.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _refreshConnectivity();
    _connSub = Connectivity().onConnectivityChanged.listen((_) {
      _refreshConnectivity();
    });
  }

  Future<void> _refreshConnectivity() async {
    final online = await hasNetworkConnection();
    if (mounted) setState(() => _offline = !online);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _connSub?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value, BookProvider bp) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      bp.setSearchQuery(value);
    });
  }

  void _openBook(BuildContext context, BookModel b) {
    final remote = b.storagePath.trim().isNotEmpty;
    final userLocal = b.id.startsWith('user_');
    if (!remote && !userLocal) {
      context.push('/books/detail', extra: b);
      return;
    }
    context.push(
      '/books/reader',
      extra: BookReaderArgs(book: b, autoDownloadIfMissing: remote),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Consumer<BookProvider>(
      builder: (context, bp, _) {
        final books = bp.books;
        final categories = bp.categories;
        final active = bp.selectedCategory;

        return Scaffold(
          body: Column(
            children: [
              if (_offline)
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
                          Icon(Icons.wifi_off, size: 18, color: c.accentGold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You are offline — books may not load.',
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
              StandardShellHeader(
                padding: const EdgeInsets.fromLTRB(4, 18, 16, 12),
                titleWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Books',
                      style: AppTheme.cormorantGaramond(
                        fontSize: 20,
                        letterSpacing: 0.6,
                        color: kOnEmeraldColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        'کتابیں',
                        style: AppTheme.amiriUrdu(
                          fontSize: 15,
                          height: 1.35,
                          color: kOnEmeraldColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                bottom: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: c.backgroundInput,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.borderDefault, width: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          SvgPicture.string(
                            _searchSvg,
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(
                              c.accentGold,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => _onSearchChanged(v, bp),
                              style: AppTheme.lato(
                                fontSize: 13,
                                color: c.textPrimary,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Search books...',
                                hintStyle: AppTheme.lato(
                                  fontSize: 13,
                                  color: c.textFaint,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final f = categories[i];
                    final sel = f == active;
                    return InkWell(
                      onTap: () => bp.filterByCategory(f),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: sel ? c.accentGold : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: sel ? c.accentGold : c.accentGold.o(0.55),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            f,
                            style: AppTheme.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? c.backgroundPrimary
                                        : c.textPrimary)
                                  : c.textMuted,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _BooksBody(
                  isLoading: bp.isLoading,
                  errorKey: bp.error,
                  books: books,
                  onRetry: bp.loadBooks,
                  onOpenBook: (b) => _openBook(context, b),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BooksBody extends StatelessWidget {
  const _BooksBody({
    required this.isLoading,
    required this.errorKey,
    required this.books,
    required this.onRetry,
    required this.onOpenBook,
  });

  final bool isLoading;
  final String? errorKey;
  final List<BookModel> books;
  final VoidCallback onRetry;
  final void Function(BookModel book) onOpenBook;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (isLoading) {
      return const _BooksShimmerGrid();
    }
    if (errorKey != null) {
      return _BooksErrorState(onRetry: onRetry);
    }
    if (books.isEmpty) {
      return const _BooksEmptyState();
    }

    return ContentColumn(
      maxWidth: ResponsiveLayout.contentMaxWidth,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        gridDelegate: ResponsiveLayout.bookGridDelegate(context),
        itemCount: books.length,
        itemBuilder: (context, i) {
          final b = books[i];
          return InkWell(
            onTap: () => onOpenBook(b),
            borderRadius: BorderRadius.circular(14),
            child: GoldCard(
              clipChild: true,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cover flexes to fill the fixed cell height, so cards are
                  // uniform and never leave dead space below the text.
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: b.coverImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const ShimmerPlaceholder(),
                            errorWidget: (context, url, error) =>
                                const GoldPatternError(),
                          ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: c.accentGold.o(0.92),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              b.category,
                              style: AppTheme.lato(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? c.backgroundPrimary
                                    : c.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.cormorantGaramond(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            b.titleUrdu,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.amiriUrdu(
                              fontSize: 12,
                              height: 1.3,
                              color: c.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.lato(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BooksShimmerGrid extends StatelessWidget {
  const _BooksShimmerGrid();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ContentColumn(
      maxWidth: ResponsiveLayout.contentMaxWidth,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        gridDelegate: ResponsiveLayout.bookGridDelegate(context),
        itemCount: 6,
        itemBuilder: (context, i) {
          return Shimmer.fromColors(
            baseColor: c.backgroundSurface,
            highlightColor: c.borderDefault.withValues(alpha: 0.35),
            period: const Duration(milliseconds: 1400),
            child: Container(
              decoration: BoxDecoration(
                color: c.backgroundSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.borderFaint, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.backgroundElevated,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.backgroundElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: c.backgroundElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BooksErrorState extends StatelessWidget {
  const _BooksErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const WifiOffGoldIcon(size: 64),
            const SizedBox(height: 20),
            Text(
              'Could not load books',
              style: AppTheme.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection',
              textAlign: TextAlign.center,
              style: AppTheme.lato(fontSize: 14, color: c.textMuted),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accentGold,
                side: BorderSide(color: c.accentGold, width: 1.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try Again',
                style: AppTheme.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.accentGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BooksEmptyState extends StatelessWidget {
  const _BooksEmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OpenBookGoldIcon(size: 72),
            const SizedBox(height: 20),
            Text(
              'No books available yet',
              style: AppTheme.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon',
              textAlign: TextAlign.center,
              style: AppTheme.lato(fontSize: 14, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

const _searchSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M10.5 18.5a8 8 0 1 1 0-16 8 8 0 0 1 0 16z" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M16.5 16.5L21 21" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>';
