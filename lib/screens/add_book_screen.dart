import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/user_book_model.dart';
import '../providers/book_provider.dart';
import '../services/pdf_cache_service.dart';
import '../services/user_books_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/screen_navigation_header.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _title = TextEditingController();
  final _titleUrdu = TextEditingController();
  final _author = TextEditingController();
  final _category = TextEditingController(text: 'My Books');
  final _description = TextEditingController();

  String? _pdfPath;
  bool _saving = false;

  final _pdfCache = PdfCacheService();
  final _userBooks = UserBooksService();

  @override
  void dispose() {
    _title.dispose();
    _titleUrdu.dispose();
    _author.dispose();
    _category.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    final path = res?.files.single.path;
    if (path == null || path.trim().isEmpty) return;
    setState(() => _pdfPath = path);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final pdf = _pdfPath;
    if (title.isEmpty || pdf == null || pdf.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add a title and select a PDF',
            style: AppTheme.lato(color: context.c.textPrimary),
          ),
          backgroundColor: context.c.backgroundElevated,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final id = 'user_${DateTime.now().microsecondsSinceEpoch}';
      await _pdfCache.cacheLocalPdfFromPath(id, pdf);

      final fileName = File(pdf).path.split(Platform.pathSeparator).last;
      final category = _category.text.trim().isEmpty ? 'My Books' : _category.text.trim();

      final model = UserBookModel(
        id: id,
        title: title,
        titleUrdu: _titleUrdu.text.trim(),
        author: _author.text.trim(),
        category: category,
        description: _description.text.trim().isEmpty
            ? 'Imported from $fileName'
            : _description.text.trim(),
        totalPages: 0,
        addedAtMs: DateTime.now().millisecondsSinceEpoch,
      );

      await _userBooks.upsertBook(model);

      if (mounted) {
        await context.read<BookProvider>().reloadUserBooks();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Book added',
            style: AppTheme.lato(color: context.c.textPrimary),
          ),
          backgroundColor: context.c.backgroundElevated,
        ),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not add book. Please try again.',
            style: AppTheme.lato(color: context.c.textPrimary),
          ),
          backgroundColor: context.c.backgroundElevated,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pdfName = _pdfPath == null
        ? 'No PDF selected'
        : _pdfPath!.split(Platform.pathSeparator).last;

    return Scaffold(
      body: Column(
        children: [
          ScreenNavigationHeader(
            title: 'Add Book',
            padding: const EdgeInsets.fromLTRB(4, 18, 16, 12),
            disableBack: _saving,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                _Field(
                  label: 'Title',
                  controller: _title,
                  hintText: 'e.g., Kashf al-Mahjub',
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
                  hintText: 'e.g., Ali ibn Uthman al-Hujwiri',
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Category',
                  controller: _category,
                  hintText: 'My Books',
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Description (optional)',
                  controller: _description,
                  hintText: 'Notes about this book...',
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
                InkWell(
                  onTap: _saving ? null : _pickPdf,
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
                        Icon(Icons.picture_as_pdf_outlined, color: c.accentGold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pdfName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.lato(
                              fontSize: 13,
                              color: _pdfPath == null ? c.textMuted : c.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'Choose',
                          style: AppTheme.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accentGold,
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
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
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? c.backgroundPrimary
                                  : c.textPrimary,
                            ),
                          )
                        : Text(
                            'Save Book',
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.textDirection,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextDirection? textDirection;

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

