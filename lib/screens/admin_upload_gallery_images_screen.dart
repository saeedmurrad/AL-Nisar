import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/gallery_image_model.dart';
import '../services/admin_gallery_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';

class AdminUploadGalleryImagesScreen extends StatefulWidget {
  const AdminUploadGalleryImagesScreen({super.key});

  @override
  State<AdminUploadGalleryImagesScreen> createState() =>
      _AdminUploadGalleryImagesScreenState();
}

class _AdminUploadGalleryImagesScreenState
    extends State<AdminUploadGalleryImagesScreen> {
  final _service = AdminGalleryService();
  bool _saving = false;
  double? _progress;
  String? _label;

  List<String> _paths = const [];

  Future<void> _pickImages() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: false,
    );
    final files = res?.files ?? const [];
    final paths = files.map((f) => f.path).whereType<String>().toList();
    if (paths.isEmpty) return;
    setState(() => _paths = paths);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.lato(color: context.c.textPrimary)),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  String _extFromPath(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.jpeg')) return 'jpeg';
    if (p.endsWith('.jpg')) return 'jpeg';
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.webp')) return 'webp';
    return 'jpeg';
  }

  Future<void> _uploadAll() async {
    if (_paths.isEmpty) {
      _snack('Please choose one or more images');
      return;
    }

    // Limit each file to avoid huge uploads.
    for (final p in _paths) {
      final f = File(p);
      if (!f.existsSync()) {
        _snack('File not found: ${p.split(Platform.pathSeparator).last}');
        return;
      }
      final bytes = f.lengthSync();
      if (bytes > 15 * 1024 * 1024) {
        _snack('One image is too large (max 15 MB)');
        return;
      }
    }

    setState(() {
      _saving = true;
      _progress = 0;
      _label = 'Uploading...';
    });

    try {
      for (var i = 0; i < _paths.length; i++) {
        final path = _paths[i];
        final filename = path.split(Platform.pathSeparator).last;
        setState(() {
          _label = 'Uploading ${i + 1}/${_paths.length} — $filename';
          _progress = i / _paths.length;
        });

        final id = _service.newId();
        final ext = _extFromPath(path);

        final task = _service.uploadImageTask(
          id: id,
          extension: ext,
          imagePath: path,
        );
        task.snapshotEvents.listen((snap) {
          final total = snap.totalBytes;
          final done = snap.bytesTransferred;
          if (total > 0 && mounted) {
            final perFile = done / total;
            final overall = (i + perFile) / _paths.length;
            setState(() => _progress = overall.clamp(0.0, 1.0));
          }
        });
        await task;

        final storagePath = _service.imageRef(id, extension: ext).fullPath;
        final url = await _service.getDownloadUrl(id, extension: ext);
        final model = GalleryImageModel(
          id: id,
          storagePath: storagePath,
          downloadUrl: url,
          uploadedAt: DateTime.now(),
          isActive: true,
        );
        await _service.upsert(model);
      }

      if (!mounted) return;
      _snack('Gallery images uploaded');
      context.pop();
    } catch (_) {
      if (!mounted) return;
      _snack('Upload failed. Check rules/auth and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _progress = null;
          _label = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: c.backgroundSurface,
              padding: const EdgeInsets.fromLTRB(10, 18, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _saving ? null : () => context.pop(),
                    icon: Icon(Icons.arrow_back, color: c.accentGold),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Upload Gallery Images',
                      style: AppTheme.cinzelHeading(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  if (_saving && _progress != null) ...[
                    Text(
                      _label ?? 'Uploading...',
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
                    'Images',
                    style: AppTheme.lato(
                      fontSize: 12,
                      color: c.textMuted.o(0.95),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _saving ? null : _pickImages,
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
                          Icon(Icons.image_outlined, color: c.accentGold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _paths.isEmpty
                                  ? 'Choose images (JPG/PNG/WEBP)'
                                  : '${_paths.length} selected',
                              style: AppTheme.lato(fontSize: 13, color: c.textPrimary),
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
                  if (_paths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._paths.take(6).map((p) {
                      final name = p.split(Platform.pathSeparator).last;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                        ),
                      );
                    }),
                    if (_paths.length > 6)
                      Text(
                        '+${_paths.length - 6} more',
                        style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                      ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _uploadAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accentGold,
                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                            ? c.backgroundPrimary
                            : c.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

