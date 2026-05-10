import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/admin_lessons_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/gold_card.dart';
import '../widgets/screen_navigation_header.dart';

class AdminLessonsScreen extends StatelessWidget {
  const AdminLessonsScreen({
    super.key,
    required this.collectionPath,
    required this.title,
    required this.emptyLabel,
  });

  final String collectionPath;
  final String title;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final service = AdminLessonsService(collectionPath: collectionPath);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.accentGold,
        foregroundColor:
            Theme.of(context).brightness == Brightness.dark ? c.backgroundPrimary : c.textPrimary,
        onPressed: () async {
          final created = await showModalBottomSheet<LessonModel?>(
            context: context,
            isScrollControlled: true,
            backgroundColor: c.backgroundSurface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) => _LessonEditor(
              initial: LessonModel(
                id: service.newId(),
                title: '',
                subtitle: '',
                pageCount: 0,
                coverImageUrl: '',
                isLocked: false,
                pages: const [],
                createdAt: DateTime.now(),
                isActive: true,
              ),
            ),
          );
          if (created == null) return;
          await service.upsert(created);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          ScreenNavigationHeader(
            title: title,
            padding: const EdgeInsets.fromLTRB(4, 18, 16, 12),
          ),
          Expanded(
            child: StreamBuilder<List<LessonModel>>(
              stream: service.streamAll(),
              builder: (context, snap) {
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return Center(
                    child: Text(emptyLabel, style: AppTheme.lato(color: c.textMuted)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final l = list[i];
                    return GoldCard(
                      backgroundColor: c.backgroundSurface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.title.isEmpty ? '(untitled)' : l.title,
                                  style: AppTheme.lato(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              Switch(
                                value: l.isActive,
                                activeThumbColor: c.accentGold,
                                onChanged: (v) => service.setActive(l.id, v),
                              ),
                            ],
                          ),
                          if (l.subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              l.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: c.backgroundElevated,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: c.borderDefault, width: 0.5),
                                ),
                                child: Text(
                                  '${l.pages.length} pages',
                                  style: AppTheme.lato(fontSize: 11, color: c.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: l.isLocked ? Colors.red.withValues(alpha: 0.12) : c.accentGold.o(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: l.isLocked ? Colors.red.withValues(alpha: 0.5) : c.accentGold.o(0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  l.isLocked ? 'Locked' : 'Unlocked',
                                  style: AppTheme.lato(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: l.isLocked ? Colors.red.shade300 : c.accentGold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () async {
                                  await service.setLocked(l.id, !l.isLocked);
                                },
                                child: Text(
                                  l.isLocked ? 'Unlock' : 'Lock',
                                  style: AppTheme.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: c.accentGold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final updated = await showModalBottomSheet<LessonModel?>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: c.backgroundSurface,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    builder: (ctx) => _LessonEditor(initial: l),
                                  );
                                  if (updated == null) return;
                                  await service.upsert(updated);
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

class _LessonEditor extends StatefulWidget {
  const _LessonEditor({required this.initial});

  final LessonModel initial;

  @override
  State<_LessonEditor> createState() => _LessonEditorState();
}

class _LessonEditorState extends State<_LessonEditor> {
  late final _title = TextEditingController(text: widget.initial.title);
  late final _subtitle = TextEditingController(text: widget.initial.subtitle);
  late final _cover = TextEditingController(text: widget.initial.coverImageUrl);
  late final _urduTitle = TextEditingController(text: widget.initial.urduTitle ?? '');
  late final _lessonNumber = TextEditingController(
    text: widget.initial.lessonNumber?.toString() ?? '',
  );

  late final List<LessonPage> _pages = [...widget.initial.pages];

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _cover.dispose();
    _urduTitle.dispose();
    _lessonNumber.dispose();
    super.dispose();
  }

  Future<void> _addOrEditPage({LessonPage? existing, int? index}) async {
    final res = await showModalBottomSheet<LessonPage?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _PageEditor(initial: existing),
    );
    if (res == null) return;
    setState(() {
      if (index != null && index >= 0 && index < _pages.length) {
        _pages[index] = res;
      } else {
        _pages.add(res);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
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
            'Lesson',
            style: AppTheme.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _Field(label: 'Title', controller: _title, hintText: 'Title'),
          const SizedBox(height: 10),
          _Field(label: 'Subtitle', controller: _subtitle, hintText: 'Subtitle'),
          const SizedBox(height: 10),
          _Field(
            label: 'Urdu title (optional)',
            controller: _urduTitle,
            hintText: 'اردو عنوان',
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 10),
          _Field(
            label: 'Lesson number (optional)',
            controller: _lessonNumber,
            hintText: 'e.g. 1',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          _Field(
            label: 'Cover image URL (optional)',
            controller: _cover,
            hintText: 'https://...',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pages (${_pages.length})',
                  style: AppTheme.lato(
                    fontSize: 12,
                    color: c.textMuted.o(0.95),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _addOrEditPage(),
                child: Text(
                  'Add page',
                  style: AppTheme.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_pages.isEmpty)
            Text('No pages yet', style: AppTheme.lato(color: c.textMuted))
          else
            SizedBox(
              height: 160,
              child: ListView.separated(
                itemCount: _pages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return InkWell(
                    onTap: () => _addOrEditPage(existing: p, index: i),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.backgroundInput,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.borderDefault, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.chapterTitle.isEmpty ? 'Page ${i + 1}' : p.chapterTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _pages.removeAt(i)),
                            icon: Icon(Icons.delete_outline, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              final ln = int.tryParse(_lessonNumber.text.trim());
              Navigator.pop(
                context,
                LessonModel(
                  id: widget.initial.id,
                  title: _title.text.trim(),
                  subtitle: _subtitle.text.trim(),
                  pageCount: _pages.length,
                  coverImageUrl: _cover.text.trim(),
                  isLocked: widget.initial.isLocked,
                  pages: _pages,
                  createdAt: widget.initial.createdAt,
                  urduTitle: _urduTitle.text.trim().isEmpty ? null : _urduTitle.text.trim(),
                  lessonNumber: ln,
                  isActive: widget.initial.isActive,
                ),
              );
            },
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
            child: Text('Save', style: AppTheme.lato(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PageEditor extends StatefulWidget {
  const _PageEditor({this.initial});

  final LessonPage? initial;

  @override
  State<_PageEditor> createState() => _PageEditorState();
}

class _PageEditorState extends State<_PageEditor> {
  late final _chapter = TextEditingController(text: widget.initial?.chapterTitle ?? '');
  late final _urdu = TextEditingController(text: widget.initial?.urdu ?? '');
  late final _english = TextEditingController(text: widget.initial?.english ?? '');

  @override
  void dispose() {
    _chapter.dispose();
    _urdu.dispose();
    _english.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
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
            'Page',
            style: AppTheme.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _Field(label: 'Chapter title', controller: _chapter, hintText: 'Chapter'),
          const SizedBox(height: 10),
          _Field(
            label: 'Urdu',
            controller: _urdu,
            hintText: 'اردو متن',
            maxLines: 4,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 10),
          _Field(
            label: 'English',
            controller: _english,
            hintText: 'English text',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                LessonPage(
                  chapterTitle: _chapter.text.trim(),
                  urdu: _urdu.text.trim(),
                  english: _english.text.trim(),
                ),
              );
            },
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
            child: Text('Save page', style: AppTheme.lato(fontWeight: FontWeight.w700)),
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

