import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/asbaq_pdf_model.dart';
import '../services/admin_asbaq_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/screen_navigation_header.dart';

class AdminUploadAsbaqScreen extends StatefulWidget {
  const AdminUploadAsbaqScreen({super.key});

  @override
  State<AdminUploadAsbaqScreen> createState() => _AdminUploadAsbaqScreenState();
}

class _AdminUploadAsbaqScreenState extends State<AdminUploadAsbaqScreen> {
  final _titleEn = TextEditingController();
  final _titleUr = TextEditingController();

  String? _pdfPath;
  String? _coverPath;
  bool _saving = false;
  double? _progress;

  final _service = AdminAsbaqService();

  @override
  void dispose() {
    _titleEn.dispose();
    _titleUr.dispose();
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

  Future<void> _pickCover() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: false,
    );
    final path = res?.files.single.path;
    if (path == null || path.trim().isEmpty) return;
    setState(() => _coverPath = path);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.lato(color: context.c.textPrimary)),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  Future<void> _upload() async {
    final en = _titleEn.text.trim();
    final ur = _titleUr.text.trim();
    final pdf = _pdfPath;
    if (en.isEmpty || ur.isEmpty || pdf == null || pdf.trim().isEmpty) {
      _snack('Please add English title, Urdu title, and select a PDF');
      return;
    }
    if (!File(pdf).existsSync()) {
      _snack('PDF file not found');
      return;
    }
    final bytes = File(pdf).lengthSync();
    if (bytes > 50 * 1024 * 1024) {
      _snack('PDF is too large (max 50 MB)');
      return;
    }

    setState(() {
      _saving = true;
      _progress = 0;
    });
    try {
      final id = _service.newId();
      final task = _service.uploadPdfTask(id: id, pdfPath: pdf);
      task.snapshotEvents.listen((snap) {
        final total = snap.totalBytes;
        final done = snap.bytesTransferred;
        if (total > 0 && mounted) {
          setState(() => _progress = done / total);
        }
      });
      await task;
      final storagePath = _service.pdfRef(id).fullPath;

      String thumbUrl = '';
      final cover = _coverPath;
      if (cover != null && cover.trim().isNotEmpty && File(cover).existsSync()) {
        final coverBytes = File(cover).lengthSync();
        if (coverBytes > 10 * 1024 * 1024) {
          _snack('Thumbnail image is too large (max 10 MB)');
          return;
        }
        final coverTask = _service.uploadThumbTask(id: id, imagePath: cover);
        coverTask.snapshotEvents.listen((snap) {
          final total = snap.totalBytes;
          final done = snap.bytesTransferred;
          if (total > 0 && mounted) {
            setState(() => _progress = done / total);
          }
        });
        await coverTask;
        thumbUrl = await _service.getThumbUrl(id: id, imagePath: cover);
      }

      final model = AsbaqPdfModel(
        id: id,
        titleEn: en,
        titleUr: ur,
        storagePath: storagePath,
        thumbnailUrl: thumbUrl,
        uploadedAt: DateTime.now(),
        isActive: true,
      );

      await _service.upsert(model);

      if (!mounted) return;
      _snack('Asbaq PDF uploaded');
      context.pop();
    } catch (_) {
      if (!mounted) return;
      _snack('Upload failed. Check rules/auth and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pdfName = _pdfPath == null
        ? 'No PDF selected'
        : _pdfPath!.split(Platform.pathSeparator).last;
    final coverName = _coverPath == null
        ? 'No thumbnail selected (optional)'
        : _coverPath!.split(Platform.pathSeparator).last;

    return Scaffold(
      body: Column(
        children: [
          ScreenNavigationHeader(
            title: 'Upload Asbaq PDF (Admin)',
            padding: const EdgeInsets.fromLTRB(4, 18, 16, 12),
            disableBack: _saving,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                if (_saving && _progress != null) ...[
                  Text(
                    'Uploading PDF...',
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
                  label: 'Title (English)',
                  controller: _titleEn,
                  hintText: 'English title',
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Title (Urdu)',
                  controller: _titleUr,
                  hintText: 'اردو عنوان',
                  textDirection: TextDirection.rtl,
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
                  'Thumbnail (optional)',
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
                    onPressed: _saving ? null : _upload,
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
    this.textDirection,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
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

