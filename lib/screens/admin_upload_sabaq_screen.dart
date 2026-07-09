import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/sabaq_pdf_model.dart';
import '../models/upload_file_data.dart';
import '../services/admin_sabaq_service.dart';
import '../utils/sabaq_order_utils.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../utils/upload_picker.dart';
import '../widgets/screen_navigation_header.dart';

class AdminUploadSabaqScreen extends StatefulWidget {
  const AdminUploadSabaqScreen({super.key});

  @override
  State<AdminUploadSabaqScreen> createState() => _AdminUploadSabaqScreenState();
}

class _AdminUploadSabaqScreenState extends State<AdminUploadSabaqScreen> {
  final _titleEn = TextEditingController();
  final _titleUr = TextEditingController();

  UploadFileData? _pdfFile;
  UploadFileData? _coverFile;
  bool _saving = false;
  double? _progress;

  final _service = AdminSabaqService();

  @override
  void dispose() {
    _titleEn.dispose();
    _titleUr.dispose();
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
    final pdf = _pdfFile;
    if (en.isEmpty || ur.isEmpty || pdf == null) {
      _snack('Please add English title, Urdu title, and select a PDF');
      return;
    }
    final bytes = pdf.length;
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
      final task = _service.uploadPdfTask(id: id, pdf: pdf);
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
      final cover = _coverFile;
      if (cover != null) {
        final coverBytes = cover.length;
        if (coverBytes > 10 * 1024 * 1024) {
          _snack('Thumbnail image is too large (max 10 MB)');
          return;
        }
        final coverTask = _service.uploadThumbTask(id: id, image: cover);
        coverTask.snapshotEvents.listen((snap) {
          final total = snap.totalBytes;
          final done = snap.bytesTransferred;
          if (total > 0 && mounted) {
            setState(() => _progress = done / total);
          }
        });
        await coverTask;
        thumbUrl = await _service.getThumbUrl(id: id, imageName: cover.name);
      }

      final model = SabaqPdfModel(
        id: id,
        titleEn: en,
        titleUr: ur,
        storagePath: storagePath,
        thumbnailUrl: thumbUrl,
        uploadedAt: DateTime.now(),
        isActive: true,
        orderNumber: parseSabaqOrderNumber(en, titleUr: ur),
      );

      await _service.upsert(model);
      await _service.deactivateOlderDuplicates(model);

      if (!mounted) return;
      _snack('Sabaq PDF uploaded');
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
    final pdfName = _pdfFile?.name ?? 'No PDF selected';
    final coverName = _coverFile?.name ?? 'No thumbnail selected (optional)';

    return Scaffold(
      body: Column(
        children: [
          ScreenNavigationHeader(
            title: 'Upload Sabaq PDF (Admin)',
            padding: const EdgeInsets.fromLTRB(4, 18, 16, 12),
            disableBack: _saving,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                if (_saving && _progress != null) ...[
                  Text(
                    'Uploading…',
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
