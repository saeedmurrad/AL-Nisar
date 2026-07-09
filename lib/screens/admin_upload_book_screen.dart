import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book_model.dart';
import '../models/upload_file_data.dart';
import '../providers/book_provider.dart';
import '../services/admin_books_service.dart';
import '../services/pdf_cover_extractor.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../utils/file_bytes_utils.dart';
import '../utils/upload_picker.dart';
import '../widgets/screen_navigation_header.dart';
import '../widgets/shimmer_placeholder.dart';

class AdminUploadBookScreen extends StatefulWidget {
  const AdminUploadBookScreen({super.key});

  @override
  State<AdminUploadBookScreen> createState() => _AdminUploadBookScreenState();
}

class _AdminUploadBookScreenState extends State<AdminUploadBookScreen> {
  final _title = TextEditingController();
  final _titleUrdu = TextEditingController();
  final _author = TextEditingController();
  final _category = TextEditingController(text: 'Books');
  final _description = TextEditingController();
  final _totalPages = TextEditingController();

  UploadFileData? _pdfFile;
  UploadFileData? _coverFile;
  bool _saving = false;
  double? _progress;
  String? _progressLabel;

  final _service = AdminBooksService();
  final Set<String> _deletingBookIds = {};

  @override
  void dispose() {
    _title.dispose();
    _titleUrdu.dispose();
    _author.dispose();
    _category.dispose();
    _description.dispose();
    _totalPages.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final file = await pickUploadFile(allowedExtensions: const ['pdf']);
    if (file == null) return;
    setState(() => _pdfFile = file);
  }

  Future<void> _pickCover() async {
    final file = await pickUploadFile(
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (file == null) return;
    setState(() => _coverFile = file);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final pdf = _pdfFile;
    if (title.isEmpty || pdf == null) {
      _snack('Please add a title and select a PDF');
      return;
    }
    final pdfBytes = pdf.length;
    // Keep a sane limit for mobile uploads.
    if (pdfBytes > 50 * 1024 * 1024) {
      _snack('PDF is too large (max 50 MB)');
      return;
    }

    setState(() => _saving = true);
    try {
      final analyzed = await extractPdfPageCountAndCover(pdf.bytes);
      final extractedPages = analyzed.pageCount;
      final thumbPng = analyzed.coverPng;
      if (mounted && extractedPages > 0) {
        _totalPages.text = '$extractedPages';
      }

      final id = await _service.createNewBookId();
      setState(() {
        _progress = 0;
        _progressLabel = 'Uploading PDF...';
      });
      final pdfTask = _service.uploadBookPdfTask(bookId: id, pdf: pdf);
      pdfTask.snapshotEvents.listen((snap) {
        final total = snap.totalBytes;
        final done = snap.bytesTransferred;
        if (total > 0 && mounted) {
          setState(() => _progress = done / total);
        }
      });
      await pdfTask;
      final storagePath = _service.bookPdfRef(id).fullPath;

      String coverUrl = '';
      final cover = _coverFile;
      if (cover != null) {
        final coverBytes = cover.length;
        if (coverBytes > 10 * 1024 * 1024) {
          _snack('Cover image is too large (max 10 MB)');
          return;
        }
        setState(() {
          _progress = 0;
          _progressLabel = 'Uploading cover...';
        });
        final coverTask = _service.uploadCoverImageTask(
          bookId: id,
          image: cover,
        );
        coverTask.snapshotEvents.listen((snap) {
          final total = snap.totalBytes;
          final done = snap.bytesTransferred;
          if (total > 0 && mounted) {
            setState(() => _progress = done / total);
          }
        });
        await coverTask;
        final ext = imageExtensionFromName(cover.name);
        coverUrl = await _service
            .bookCoverRef(id, extension: ext)
            .getDownloadURL();
      } else if (thumbPng != null && thumbPng.isNotEmpty) {
        setState(() {
          _progress = 0;
          _progressLabel = 'Uploading cover from PDF…';
        });
        final coverTask = _service.uploadCoverPngDataTask(
          bookId: id,
          pngBytes: thumbPng,
        );
        coverTask.snapshotEvents.listen((snap) {
          final total = snap.totalBytes;
          final done = snap.bytesTransferred;
          if (total > 0 && mounted) {
            setState(() => _progress = done / total);
          }
        });
        await coverTask;
        coverUrl = await _service
            .bookCoverRef(id, extension: 'png')
            .getDownloadURL();
      }

      final manualPages = int.tryParse(_totalPages.text.trim()) ?? 0;
      final totalPages = extractedPages > 0 ? extractedPages : manualPages;
      final model = BookModel(
        id: id,
        title: title,
        titleUrdu: _titleUrdu.text.trim(),
        author: _author.text.trim(),
        category: _category.text.trim().isEmpty
            ? 'Books'
            : _category.text.trim(),
        description: _description.text.trim(),
        storagePath: storagePath,
        coverImageUrl: coverUrl,
        totalPages: totalPages,
        uploadedAt: DateTime.now(),
        isActive: true,
      );

      await _service.saveBookMetadata(model);

      if (!mounted) return;
      context.read<BookProvider>().loadBooks();
      _snack('Book uploaded to Firebase');
      context.pop();
    } catch (_) {
      if (!mounted) return;
      _snack('Upload failed. Check rules/auth and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _progress = null;
          _progressLabel = null;
        });
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.lato(color: context.c.textPrimary)),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  Future<void> _confirmDeleteBook(BookModel book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cc = ctx.c;
        return AlertDialog(
          backgroundColor: cc.backgroundSurface,
          title: Text(
            'Delete book?',
            style: AppTheme.cormorantGaramond(color: cc.textPrimary),
          ),
          content: Text(
            '"${book.title.isEmpty ? book.id : book.title}" will be removed from the app, including the PDF and cover in Storage when possible.',
            style: AppTheme.lato(fontSize: 13, color: cc.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: AppTheme.lato(color: cc.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete', style: AppTheme.lato(color: cc.accentGold)),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _deletingBookIds.add(book.id));
    try {
      final outcome = await _service.deleteBook(book);
      if (!mounted) return;
      context.read<BookProvider>().loadBooks();
      if (!outcome.pdfOk || !outcome.coverOk) {
        _snack('Book removed; some Storage files may still exist.');
      } else {
        _snack('Book deleted');
      }
    } catch (_) {
      if (mounted) _snack('Delete failed. Check connection/rules.');
    } finally {
      if (mounted) setState(() => _deletingBookIds.remove(book.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pdfName = _pdfFile?.name ?? 'No PDF selected';
    final coverName = _coverFile?.name ?? 'No cover selected (optional)';

    return Scaffold(
      body: Column(
        children: [
          ScreenNavigationHeader(
            title: 'Upload Book (Admin)',
            padding: const EdgeInsets.fromLTRB(4, 18, 16, 12),
            disableBack: _saving,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                Text(
                  'Published books',
                  style: AppTheme.lato(
                    fontSize: 12,
                    color: c.textMuted.o(0.95),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<BookModel>>(
                  stream: _service.streamAllBooks(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        (snap.data == null || snap.data!.isEmpty)) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(color: c.accentGold),
                        ),
                      );
                    }
                    final list = snap.data ?? const <BookModel>[];
                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No books in Firebase yet',
                          style: AppTheme.lato(
                            fontSize: 13,
                            color: c.textMuted,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: list.map((b) {
                        final busy = _deletingBookIds.contains(b.id);
                        final cover = b.coverImageUrl.trim();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: c.backgroundInput,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: c.borderDefault,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: cover.isEmpty
                                      ? Container(
                                          width: 40,
                                          height: 56,
                                          color: c.backgroundElevated,
                                          child: Icon(
                                            Icons.menu_book_outlined,
                                            color: c.textMuted,
                                            size: 22,
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: cover,
                                          width: 40,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const ShimmerPlaceholder(),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                width: 40,
                                                height: 56,
                                                color: c.backgroundElevated,
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: c.textMuted,
                                                  size: 20,
                                                ),
                                              ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.title.isEmpty ? b.id : b.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.lato(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      if (!b.isActive)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            'Hidden',
                                            style: AppTheme.lato(
                                              fontSize: 11,
                                              color: c.textMuted,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (busy)
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: c.accentGold,
                                    ),
                                  )
                                else
                                  IconButton(
                                    onPressed: _saving
                                        ? null
                                        : () => _confirmDeleteBook(b),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: c.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'Upload new',
                  style: AppTheme.lato(
                    fontSize: 12,
                    color: c.textMuted.o(0.95),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                if (_saving && _progress != null) ...[
                  Text(
                    _progressLabel ?? 'Uploading...',
                    style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: c.backgroundElevated,
                      color: c.accentGold,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _Field(
                  label: 'Title',
                  controller: _title,
                  hintText: 'Book title',
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Title (Urdu/Arabic) (optional)',
                  controller: _titleUrdu,
                  hintText: 'مثال',
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Author (optional)',
                  controller: _author,
                  hintText: 'Author name',
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Category',
                  controller: _category,
                  hintText: 'Books',
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Total Pages (optional)',
                  controller: _totalPages,
                  hintText: 'e.g. 120',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Description (optional)',
                  controller: _description,
                  hintText: 'Short description...',
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Text(
                  'PDF',
                  style: AppTheme.lato(
                    fontSize: 12,
                    color: c.textMuted.o(0.95),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _PickerRow(
                  icon: Icons.picture_as_pdf_outlined,
                  label: pdfName,
                  actionLabel: 'Choose',
                  onTap: _saving ? null : _pickPdf,
                ),
                const SizedBox(height: 12),
                Text(
                  'Cover (optional)',
                  style: AppTheme.lato(
                    fontSize: 12,
                    color: c.textMuted.o(0.95),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _PickerRow(
                  icon: Icons.image_outlined,
                  label: coverName,
                  actionLabel: 'Choose',
                  onTap: _saving ? null : _pickCover,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accentGold,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? c.backgroundPrimary
                          : c.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? c.backgroundPrimary
                                  : c.textPrimary,
                            ),
                          )
                        : Text(
                            'Upload',
                            style: AppTheme.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: c.backgroundInput,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.borderDefault, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.accentGold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.lato(fontSize: 13, color: c.textPrimary),
              ),
            ),
            Text(
              actionLabel,
              style: AppTheme.lato(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.accentGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.textDirection,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextDirection? textDirection;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lato(
            fontSize: 12,
            color: c.textMuted.o(0.95),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textDirection: textDirection,
          keyboardType: keyboardType,
          style: AppTheme.lato(fontSize: 13, color: c.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: c.backgroundInput,
            hintText: hintText,
            hintStyle: AppTheme.lato(fontSize: 13, color: c.textFaint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.borderDefault, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.borderDefault, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.accentGold.o(0.7), width: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}
