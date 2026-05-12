import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/irshad_firestore_model.dart';
import '../services/admin_irshadat_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/gold_card.dart';
import '../widgets/screen_navigation_header.dart';
import '../widgets/shimmer_placeholder.dart';

class AdminIrshadatScreen extends StatefulWidget {
  const AdminIrshadatScreen({
    super.key,
    this.initialLanguage = IrshadatLanguage.urdu,
  });

  final IrshadatLanguage initialLanguage;

  @override
  State<AdminIrshadatScreen> createState() => _AdminIrshadatScreenState();
}

class _AdminIrshadatScreenState extends State<AdminIrshadatScreen> {
  late IrshadatLanguage _language = widget.initialLanguage;
  final Set<String> _deletingIrshadIds = {};

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.lato(color: context.c.textPrimary)),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  Future<void> _confirmDeleteIrshad(
    AdminIrshadatService service,
    IrshadFirestoreModel ir,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cc = ctx.c;
        return AlertDialog(
          backgroundColor: cc.backgroundSurface,
          title: Text(
            'Delete Irshad?',
            style: AppTheme.cormorantGaramond(color: cc.textPrimary),
          ),
          content: Text(
            'This removes this entry and its image from Firebase when possible.',
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
    setState(() => _deletingIrshadIds.add(ir.id));
    try {
      final storageOk = await service.deleteIrshad(_language, ir);
      if (!mounted) return;
      if (!storageOk) {
        _snack('Irshad removed; image file may still exist in Storage.');
      } else {
        _snack('Irshad deleted');
      }
    } catch (_) {
      if (mounted) _snack('Delete failed. Check connection/rules.');
    } finally {
      if (mounted) setState(() => _deletingIrshadIds.remove(ir.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final service = AdminIrshadatService();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.accentGold,
        foregroundColor:
            Theme.of(context).brightness == Brightness.dark ? c.backgroundPrimary : c.textPrimary,
        onPressed: () async {
          final created = await showModalBottomSheet<IrshadFirestoreModel?>(
            context: context,
            isScrollControlled: true,
            backgroundColor: c.backgroundSurface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) => _IrshadEditor(
              initial: IrshadFirestoreModel(
                id: service.newId(_language),
                dateLabel: '',
                text: '',
                imageUrl: '',
                createdAt: DateTime.now(),
                isActive: true,
              ),
              language: _language,
            ),
          );
          if (created == null) return;
          await service.upsert(_language, created);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const ScreenNavigationHeader(
            title: 'Manage Irshadat',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 12),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _LangPill(
                    label: 'Urdu',
                    selected: _language == IrshadatLanguage.urdu,
                    onTap: () => setState(() => _language = IrshadatLanguage.urdu),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LangPill(
                    label: 'English',
                    selected: _language == IrshadatLanguage.english,
                    onTap: () => setState(() => _language = IrshadatLanguage.english),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<IrshadFirestoreModel>>(
              stream: service.streamAll(_language),
              builder: (context, snap) {
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No Irshadat yet',
                      style: AppTheme.lato(color: c.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final ir = list[i];
                    final deleting = _deletingIrshadIds.contains(ir.id);
                    final hasImage = ir.imageUrl.trim().isNotEmpty;
                    return GoldCard(
                      backgroundColor: c.backgroundSurface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (hasImage) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: ir.imageUrl,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                    placeholder: (context, url) => Container(
                                      width: 64,
                                      height: 64,
                                      color: c.backgroundInput,
                                      child: const ShimmerPlaceholder(),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      width: 64,
                                      height: 64,
                                      color: c.backgroundInput,
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: c.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Text(
                                  ir.dateLabel.isEmpty ? '(no date label)' : ir.dateLabel,
                                  style: AppTheme.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              Switch(
                                value: ir.isActive,
                                activeThumbColor: c.accentGold,
                                onChanged: deleting
                                    ? null
                                    : (v) => service.setActive(_language, ir.id, v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _language.isRtl
                              ? Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    ir.text,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.amiriUrdu(
                                      fontSize: 14,
                                      height: 1.9,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                )
                              : Text(
                                  ir.text,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.lato(
                                    fontSize: 12,
                                    color: c.textMuted,
                                    height: 1.4,
                                  ).copyWith(fontStyle: FontStyle.italic),
                                ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Spacer(),
                              if (deleting)
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: c.accentGold,
                                  ),
                                )
                              else ...[
                                TextButton(
                                  onPressed: () => _confirmDeleteIrshad(service, ir),
                                  child: Text(
                                    'Delete',
                                    style: AppTheme.lato(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: c.textMuted,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final updated =
                                        await showModalBottomSheet<IrshadFirestoreModel?>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: c.backgroundSurface,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      builder: (ctx) =>
                                          _IrshadEditor(initial: ir, language: _language),
                                    );
                                    if (updated == null) return;
                                    await service.upsert(_language, updated);
                                  },
                                  child: Text(
                                    'Edit',
                                    style: AppTheme.lato(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: c.accentGold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IrshadEditor extends StatefulWidget {
  const _IrshadEditor({required this.initial, required this.language});

  final IrshadFirestoreModel initial;
  final IrshadatLanguage language;

  @override
  State<_IrshadEditor> createState() => _IrshadEditorState();
}

class _IrshadEditorState extends State<_IrshadEditor> {
  late final _date = TextEditingController(text: widget.initial.dateLabel);
  late final _text = TextEditingController(text: widget.initial.text);
  String? _imagePath;
  bool _saving = false;

  @override
  void dispose() {
    _date.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: false,
    );
    final path = res?.files.single.path;
    if (path == null || path.trim().isEmpty) return;
    setState(() => _imagePath = path);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      builder: (ctx, child) {
        final c = ctx.c;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: c.accentGold,
                  onPrimary: Theme.of(ctx).brightness == Brightness.dark
                      ? c.backgroundPrimary
                      : c.textPrimary,
                  surface: c.backgroundSurface,
                  onSurface: c.textPrimary,
                ),
            dialogTheme: Theme.of(ctx).dialogTheme.copyWith(
                  backgroundColor: c.backgroundSurface,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    _date.text = _formatDateLabel(picked);
  }

  String _formatDateLabel(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[d.month - 1];
    return '${d.day.toString().padLeft(2, '0')} $m ${d.year}';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.lato(color: context.c.textPrimary)),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  Future<void> _save() async {
    final dateLabel = _date.text.trim();
    final text = _text.text.trim();

    if (dateLabel.isEmpty) {
      _snack('Please add a date label');
      return;
    }

    setState(() => _saving = true);
    try {
      String imageUrl = widget.initial.imageUrl;
      final img = _imagePath;
      if (img != null && img.trim().isNotEmpty && File(img).existsSync()) {
        final bytes = File(img).lengthSync();
        if (bytes > 10 * 1024 * 1024) {
          _snack('Image is too large (max 10 MB)');
          return;
        }
        imageUrl =
            (await AdminIrshadatService().uploadImage(
                  language: widget.language,
                  id: widget.initial.id,
                  imagePath: img,
                )) ??
                imageUrl;
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        IrshadFirestoreModel(
          id: widget.initial.id,
          dateLabel: dateLabel,
          text: text,
          imageUrl: imageUrl,
          createdAt: widget.initial.createdAt,
          isActive: widget.initial.isActive,
        ),
      );
    } catch (_) {
      _snack('Save failed. Check connection/rules and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final imgName = _imagePath == null
        ? 'No image selected (optional)'
        : _imagePath!.split(Platform.pathSeparator).last;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Irshad',
            style: AppTheme.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Date label',
            controller: _date,
            hintText: 'e.g., 14 Apr 2026',
            readOnly: true,
            onTap: _saving ? null : _pickDate,
          ),
          const SizedBox(height: 10),
          _Field(
            label: widget.language.label,
            controller: _text,
            hintText: widget.language.isRtl ? 'اردو متن (optional)' : 'English text (optional)',
            maxLines: widget.language.isRtl ? 4 : 3,
            textDirection: widget.language.isRtl ? TextDirection.rtl : null,
          ),
          const SizedBox(height: 10),
          Text(
            'Image (optional)',
            style: AppTheme.lato(
              fontSize: 12,
              color: c.textMuted.o(0.95),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _saving ? null : _pickImage,
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
                      imgName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.accentGold,
              foregroundColor:
                  Theme.of(context).brightness == Brightness.dark ? c.backgroundPrimary : c.textPrimary,
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
                : Text('Save', style: AppTheme.lato(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
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
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextDirection? textDirection;
  final bool readOnly;
  final VoidCallback? onTap;

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
          readOnly: readOnly,
          onTap: onTap,
          style: AppTheme.lato(fontSize: 13, color: c.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: c.backgroundInput,
            hintText: hintText,
            hintStyle: AppTheme.lato(fontSize: 13, color: c.textFaint),
            suffixIcon: readOnly
                ? Icon(Icons.calendar_today_outlined, size: 18, color: c.accentGold)
                : null,
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

class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.backgroundElevated : c.backgroundInput,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? c.accentGold.o(0.55) : c.borderDefault,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? c.textPrimary : c.textMuted,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

