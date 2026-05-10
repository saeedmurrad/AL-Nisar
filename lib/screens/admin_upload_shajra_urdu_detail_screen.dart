import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/shajra_entry_model.dart';
import '../models/shajra_urdu_detail_model.dart';
import '../services/admin_shajra_urdu_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/screen_navigation_header.dart';

class AdminUploadShajraUrduDetailScreen extends StatefulWidget {
  const AdminUploadShajraUrduDetailScreen({super.key, required this.args});

  final AdminShajraUrduUploadArgs args;

  @override
  State<AdminUploadShajraUrduDetailScreen> createState() =>
      _AdminUploadShajraUrduDetailScreenState();
}

class _AdminUploadShajraUrduDetailScreenState
    extends State<AdminUploadShajraUrduDetailScreen> {
  final _service = AdminShajraUrduService();
  String? _pdfPath;
  bool _saving = false;
  double? _progress;

  ShajraEntryModel get _entry => widget.args.entry;

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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.lato(color: context.c.textPrimary)),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  Future<void> _upload() async {
    final pdf = _pdfPath;
    if (pdf == null || pdf.trim().isEmpty) {
      _snack('Please select a PDF');
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
      final number = _entry.number;
      final task = _service.uploadPdfTask(number: number, pdfPath: pdf);
      task.snapshotEvents.listen((snap) {
        final total = snap.totalBytes;
        final done = snap.bytesTransferred;
        if (total > 0 && mounted) {
          setState(() => _progress = done / total);
        }
      });
      await task;
      final storagePath = _service.pdfRef(number).fullPath;

      final model = ShajraUrduDetailModel(
        number: number,
        titleUrdu: _entry.fullTitle,
        storagePath: storagePath,
        updatedAt: DateTime.now(),
        isActive: true,
      );
      await _service.upsertDetail(model);

      if (!mounted) return;
      _snack('Urdu Shajra PDF uploaded');
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

    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            ScreenNavigationHeader(
              title: 'Upload Urdu Shajra PDF',
              padding: const EdgeInsets.fromLTRB(4, 18, 16, 12),
              disableBack: _saving,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.backgroundSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.borderDefault, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'No. ${_entry.number}',
                          style: AppTheme.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: c.accentGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            _entry.fullTitle,
                            style: AppTheme.amiriUrdu(
                              fontSize: 18,
                              height: 1.9,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
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

