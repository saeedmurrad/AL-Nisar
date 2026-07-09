import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/gallery_folder.dart';
import '../models/gallery_image_model.dart';
import '../models/upload_file_data.dart';
import '../services/admin_gallery_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../utils/file_bytes_utils.dart';
import '../utils/upload_picker.dart';
import '../widgets/screen_navigation_header.dart';
import '../widgets/shimmer_placeholder.dart';

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
  String _uploadFolder = GalleryFolder.saeenG.id;

  List<UploadFileData> _files = const [];
  final Set<String> _deletingIds = {};

  Future<void> _pickImages() async {
    final files = await pickMultipleUploadFiles(
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (files.isEmpty) return;
    setState(() => _files = files);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.lato(color: context.c.textPrimary)),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  Future<void> _confirmDeleteGalleryImage(GalleryImageModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cc = ctx.c;
        return AlertDialog(
          backgroundColor: cc.backgroundSurface,
          title: Text(
            'Delete gallery image?',
            style: AppTheme.cormorantGaramond(color: cc.textPrimary),
          ),
          content: Text(
            'This removes the image from the app and Firebase.',
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
    setState(() => _deletingIds.add(item.id));
    try {
      final storageOk = await _service.deleteGalleryImage(item);
      if (!mounted) return;
      if (!storageOk) {
        _snack('Removed from gallery; storage file may still exist.');
      } else {
        _snack('Image deleted');
      }
    } catch (_) {
      if (mounted) _snack('Delete failed. Check connection/rules.');
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(item.id));
      }
    }
  }

  Future<void> _changeFolder(GalleryImageModel item) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cc = ctx.c;
        return SimpleDialog(
          backgroundColor: cc.backgroundSurface,
          title: Text(
            'Move to folder',
            style: AppTheme.cormorantGaramond(color: cc.textPrimary),
          ),
          children: GalleryFolder.visibleInGallery
              .map(
                (f) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, f.id),
                  child: Text(
                    f.label,
                    style: AppTheme.lato(
                      color: item.folder == f.id
                          ? cc.accentGold
                          : cc.textPrimary,
                      fontWeight: item.folder == f.id
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
    if (picked == null || picked == item.folder || !mounted) return;
    try {
      await _service.updateFolder(item.id, picked);
      if (mounted) _snack('Moved to ${GalleryFolder.fromId(picked).label}');
    } catch (_) {
      if (mounted) _snack('Could not update folder');
    }
  }

  Future<void> _uploadAll() async {
    if (_files.isEmpty) {
      _snack('Please choose one or more images');
      return;
    }

    for (final file in _files) {
      final bytes = file.length;
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
      for (var i = 0; i < _files.length; i++) {
        final file = _files[i];
        final filename = file.name;
        setState(() {
          _label = 'Uploading ${i + 1}/${_files.length} — $filename';
          _progress = i / _files.length;
        });

        final id = _service.newId();
        final ext = imageExtensionFromName(file.name);

        final task = _service.uploadImageTask(id: id, image: file);
        task.snapshotEvents.listen((snap) {
          final total = snap.totalBytes;
          final done = snap.bytesTransferred;
          if (total > 0 && mounted) {
            final perFile = done / total;
            final overall = (i + perFile) / _files.length;
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
          folder: _uploadFolder,
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
            ScreenNavigationHeader(
              title: 'Upload Gallery Images',
              padding: const EdgeInsets.fromLTRB(4, 18, 16, 12),
              disableBack: _saving,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
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
                  DropdownButtonFormField<String>(
                    value: _uploadFolder,
                    decoration: InputDecoration(
                      labelText: 'Folder',
                      labelStyle: AppTheme.lato(
                        fontSize: 12,
                        color: c.textMuted,
                      ),
                      filled: true,
                      fillColor: c.backgroundInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: c.borderDefault,
                          width: 0.5,
                        ),
                      ),
                    ),
                    dropdownColor: c.backgroundSurface,
                    style: AppTheme.lato(fontSize: 13, color: c.textPrimary),
                    items: [
                      for (final f in GalleryFolder.visibleInGallery)
                        DropdownMenuItem(value: f.id, child: Text(f.label)),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) {
                            if (v != null) setState(() => _uploadFolder = v);
                          },
                  ),
                  const SizedBox(height: 14),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
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
                              _files.isEmpty
                                  ? 'Choose images (JPG/PNG/WEBP)'
                                  : '${_files.length} selected',
                              style: AppTheme.lato(
                                fontSize: 13,
                                color: c.textPrimary,
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
                  if (_files.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._files.take(6).map((file) {
                      final name = file.name;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.lato(
                            fontSize: 12,
                            color: c.textMuted,
                          ),
                        ),
                      );
                    }),
                    if (_files.length > 6)
                      Text(
                        '+${_files.length - 6} more',
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
                  const SizedBox(height: 24),
                  Text(
                    'Uploaded images',
                    style: AppTheme.lato(
                      fontSize: 12,
                      color: c.textMuted.o(0.95),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<GalleryImageModel>>(
                    stream: _service.streamAll(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting &&
                          (snap.data == null || snap.data!.isEmpty)) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: c.accentGold,
                            ),
                          ),
                        );
                      }
                      final list = snap.data ?? const <GalleryImageModel>[];
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'No images in Firebase yet',
                            style: AppTheme.lato(
                              fontSize: 13,
                              color: c.textMuted,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: list.map((img) {
                          final busy = _deletingIds.contains(img.id);
                          final idShort = img.id.length > 10
                              ? '${img.id.substring(0, 10)}…'
                              : img.id;
                          final label =
                              '${GalleryFolder.fromId(img.folder).label} · $idShort';
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
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: img.downloadUrl.isEmpty
                                        ? Container(
                                            width: 48,
                                            height: 48,
                                            color: c.backgroundElevated,
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: c.textMuted,
                                              size: 22,
                                            ),
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: img.downloadUrl,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const ShimmerPlaceholder(),
                                            errorWidget:
                                                (
                                                  context,
                                                  url,
                                                  error,
                                                ) => Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: c.backgroundElevated,
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                    color: c.textMuted,
                                                    size: 22,
                                                  ),
                                                ),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.lato(
                                        fontSize: 13,
                                        color: c.textPrimary,
                                      ),
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: _saving
                                              ? null
                                              : () => _changeFolder(img),
                                          icon: Icon(
                                            Icons.drive_file_move_outline,
                                            color: c.accentGold,
                                          ),
                                          tooltip: 'Change folder',
                                        ),
                                        IconButton(
                                          onPressed: _saving
                                              ? null
                                              : () =>
                                                    _confirmDeleteGalleryImage(
                                                      img,
                                                    ),
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: c.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
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
