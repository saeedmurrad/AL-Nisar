import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/event_firestore_model.dart';
import '../models/news_firestore_model.dart';
import '../services/admin_news_events_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_colors.dart';
import '../theme/color_utils.dart';
import '../widgets/gold_card.dart';
import '../widgets/screen_navigation_header.dart';

class AdminNewsEventsScreen extends StatefulWidget {
  const AdminNewsEventsScreen({super.key});

  @override
  State<AdminNewsEventsScreen> createState() => _AdminNewsEventsScreenState();
}

class _AdminNewsEventsScreenState extends State<AdminNewsEventsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _service = AdminNewsEventsService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _createNews() async {
    final created = await showModalBottomSheet<NewsFirestoreModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _NewsEditor(
        initial: NewsFirestoreModel(
          id: _service.newNewsId(),
          title: '',
          category: '',
          dateLabel: '',
          imageUrl: '',
          readTime: '5 min read',
          bodyParagraphs: const [],
          createdAt: DateTime.now(),
          isActive: true,
        ),
        service: _service,
      ),
    );
    if (created == null) return;
    await _service.upsertNews(created);
  }

  Future<void> _createEvent() async {
    final created = await showModalBottomSheet<EventFirestoreModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _EventEditor(
        initial: EventFirestoreModel(
          id: _service.newEventId(),
          title: '',
          urduTitle: '',
          day: 1,
          monthAbbr: '',
          fullDateLine: '',
          shortDateLabel: '',
          location: '',
          timeLabel: '',
          organizer: 'Darbar Sharif',
          descriptionLines: const [],
          createdAt: DateTime.now(),
          isActive: true,
        ),
        service: _service,
      ),
    );
    if (created == null) return;
    await _service.upsertEvent(created);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: c.accentGold,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? c.backgroundPrimary
            : c.textPrimary,
        onPressed: () async {
          if (_tab.index == 0) {
            await _createNews();
          } else {
            await _createEvent();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const ScreenNavigationHeader(
            title: 'News & Events',
            padding: EdgeInsets.fromLTRB(4, 18, 16, 12),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _TabPill(
                    label: 'News',
                    selected: _tab.index == 0,
                    onTap: () => _tab.animateTo(0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TabPill(
                    label: 'Events',
                    selected: _tab.index == 1,
                    onTap: () => _tab.animateTo(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                StreamBuilder<List<NewsFirestoreModel>>(
                  stream: _service.streamAllNews(),
                  builder: (context, snap) {
                    final list = snap.data ?? const [];
                    if (list.isEmpty) {
                      return Center(
                        child: Text('No news yet', style: AppTheme.lato(color: c.textMuted)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final n = list[i];
                        return GoldCard(
                          backgroundColor: c.backgroundSurface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title.isEmpty ? '(untitled)' : n.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: n.isActive,
                                    activeThumbColor: c.accentGold,
                                    onChanged: (v) => _service.setNewsActive(n.id, v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${n.category} · ${n.dateLabel}',
                                style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () async {
                                      final updated =
                                          await showModalBottomSheet<NewsFirestoreModel?>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: c.backgroundSurface,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                        ),
                                        builder: (ctx) => _NewsEditor(initial: n, service: _service),
                                      );
                                      if (updated == null) return;
                                      await _service.upsertNews(updated);
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
                StreamBuilder<List<EventFirestoreModel>>(
                  stream: _service.streamAllEvents(),
                  builder: (context, snap) {
                    final list = snap.data ?? const [];
                    if (list.isEmpty) {
                      return Center(
                        child: Text('No events yet', style: AppTheme.lato(color: c.textMuted)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final e = list[i];
                        return GoldCard(
                          backgroundColor: c.backgroundSurface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.title.isEmpty ? '(untitled)' : e.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: e.isActive,
                                    activeThumbColor: c.accentGold,
                                    onChanged: (v) => _service.setEventActive(e.id, v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  e.urduTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.amiriUrdu(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${e.fullDateLine} · ${e.timeLabel}',
                                style: AppTheme.lato(fontSize: 12, color: c.textMuted),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () async {
                                      final updated =
                                          await showModalBottomSheet<EventFirestoreModel?>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: c.backgroundSurface,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                        ),
                                        builder: (ctx) => _EventEditor(initial: e, service: _service),
                                      );
                                      if (updated == null) return;
                                      await _service.upsertEvent(updated);
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
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

class _NewsEditor extends StatefulWidget {
  const _NewsEditor({required this.initial, required this.service});

  final NewsFirestoreModel initial;
  final AdminNewsEventsService service;

  @override
  State<_NewsEditor> createState() => _NewsEditorState();
}

class _NewsEditorState extends State<_NewsEditor> {
  late final _title = TextEditingController(text: widget.initial.title);
  late final _category = TextEditingController(text: widget.initial.category);
  late final _dateLabel = TextEditingController(text: widget.initial.dateLabel);
  late final _readTime = TextEditingController(text: widget.initial.readTime);
  late final _body = TextEditingController(text: widget.initial.bodyParagraphs.join('\n\n'));

  String? _imagePath;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _dateLabel.dispose();
    _readTime.dispose();
    _body.dispose();
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.lato(color: context.c.textPrimary)),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final category = _category.text.trim();
    final dateLabel = _dateLabel.text.trim();
    final readTime = _readTime.text.trim().isEmpty ? '5 min read' : _readTime.text.trim();
    final body = _body.text
        .split(RegExp(r'\n\s*\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (title.isEmpty || category.isEmpty || dateLabel.isEmpty || body.isEmpty) {
      _snack('Please fill title, category, date, and body');
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
        imageUrl = (await widget.service.uploadNewsImage(newsId: widget.initial.id, imagePath: img)) ?? imageUrl;
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        NewsFirestoreModel(
          id: widget.initial.id,
          title: title,
          category: category,
          dateLabel: dateLabel,
          imageUrl: imageUrl,
          readTime: readTime,
          bodyParagraphs: body,
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

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'News',
            style: AppTheme.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _Field(label: 'Title', controller: _title, hintText: 'Headline'),
          const SizedBox(height: 10),
          _Field(label: 'Category', controller: _category, hintText: 'Announcement / Update'),
          const SizedBox(height: 10),
          _Field(label: 'Date label', controller: _dateLabel, hintText: 'e.g., 14 Apr 2026'),
          const SizedBox(height: 10),
          _Field(label: 'Read time (optional)', controller: _readTime, hintText: 'e.g., 5 min read'),
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
          const SizedBox(height: 10),
          _Field(
            label: 'Body (separate paragraphs with blank line)',
            controller: _body,
            hintText: 'Write the article...',
            maxLines: 6,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
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
                : Text('Save', style: AppTheme.lato(fontWeight: FontWeight.w700)),
          ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventEditor extends StatefulWidget {
  const _EventEditor({required this.initial, required this.service});

  final EventFirestoreModel initial;
  final AdminNewsEventsService service;

  @override
  State<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<_EventEditor> {
  late final _title = TextEditingController(text: widget.initial.title);
  late final _urduTitle = TextEditingController(text: widget.initial.urduTitle);
  late final _day = TextEditingController(text: widget.initial.day.toString());
  late final _month = TextEditingController(text: widget.initial.monthAbbr);
  late final _fullDate = TextEditingController(text: widget.initial.fullDateLine);
  late final _shortDate = TextEditingController(text: widget.initial.shortDateLabel);
  late final _location = TextEditingController(text: widget.initial.location);
  late final _time = TextEditingController(text: widget.initial.timeLabel);
  late final _organizer = TextEditingController(text: widget.initial.organizer);
  late final _desc = TextEditingController(text: widget.initial.descriptionLines.join('\n'));

  String? _imagePath;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _urduTitle.dispose();
    _day.dispose();
    _month.dispose();
    _fullDate.dispose();
    _shortDate.dispose();
    _location.dispose();
    _time.dispose();
    _organizer.dispose();
    _desc.dispose();
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.lato(color: context.c.textPrimary)),
        backgroundColor: context.c.backgroundElevated,
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final urduTitle = _urduTitle.text.trim();
    final day = int.tryParse(_day.text.trim()) ?? 0;
    final monthAbbr = _month.text.trim();
    final fullDateLine = _fullDate.text.trim();
    final shortDateLabel = _shortDate.text.trim();
    final location = _location.text.trim();
    final timeLabel = _time.text.trim();
    final organizer = _organizer.text.trim().isEmpty ? 'Darbar Sharif' : _organizer.text.trim();
    final descLines = _desc.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (title.isEmpty ||
        urduTitle.isEmpty ||
        day <= 0 ||
        monthAbbr.isEmpty ||
        fullDateLine.isEmpty ||
        shortDateLabel.isEmpty ||
        location.isEmpty ||
        timeLabel.isEmpty) {
      _snack('Please fill all required fields');
      return;
    }

    setState(() => _saving = true);
    try {
      // We currently store only a single imageUrl in news; events screen uses no image.
      // Image upload is still supported for future use / consistency.
      final img = _imagePath;
      if (img != null && img.trim().isNotEmpty && File(img).existsSync()) {
        final bytes = File(img).lengthSync();
        if (bytes > 10 * 1024 * 1024) {
          _snack('Image is too large (max 10 MB)');
          return;
        }
        await widget.service.uploadEventImage(eventId: widget.initial.id, imagePath: img);
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        EventFirestoreModel(
          id: widget.initial.id,
          title: title,
          urduTitle: urduTitle,
          day: day,
          monthAbbr: monthAbbr,
          fullDateLine: fullDateLine,
          shortDateLabel: shortDateLabel,
          location: location,
          timeLabel: timeLabel,
          organizer: organizer,
          descriptionLines: descLines,
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

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Event',
            style: AppTheme.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _Field(label: 'Title', controller: _title, hintText: 'Event title'),
          const SizedBox(height: 10),
          _Field(
            label: 'Urdu title',
            controller: _urduTitle,
            hintText: 'اردو عنوان',
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 10),
          _Field(
            label: 'Day (1-31)',
            controller: _day,
            hintText: 'e.g., 25',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          _Field(label: 'Month abbr', controller: _month, hintText: 'e.g., APR'),
          const SizedBox(height: 10),
          _Field(label: 'Full date line', controller: _fullDate, hintText: 'e.g., 25 April 2026'),
          const SizedBox(height: 10),
          _Field(label: 'Short date label', controller: _shortDate, hintText: 'e.g., 25 Apr'),
          const SizedBox(height: 10),
          _Field(label: 'Location', controller: _location, hintText: 'Venue'),
          const SizedBox(height: 10),
          _Field(label: 'Time', controller: _time, hintText: 'e.g., After Maghrib'),
          const SizedBox(height: 10),
          _Field(label: 'Organizer (optional)', controller: _organizer, hintText: 'Darbar Sharif'),
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
          const SizedBox(height: 10),
          _Field(
            label: 'Description (optional, one line per bullet)',
            controller: _desc,
            hintText: 'Details...',
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
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
                : Text('Save', style: AppTheme.lato(fontWeight: FontWeight.w700)),
          ),
              const SizedBox(height: 8),
            ],
          ),
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

