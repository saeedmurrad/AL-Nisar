import '../models/tafseer_models.dart';

/// Renders one ruku as plain text for the clipboard.
///
/// The bundled content is HTML, but what a super admin wants to paste into a
/// message or document is readable Urdu — so tags are stripped while the inline
/// Quranic fragments stay inline, exactly where they sit in the prose.
String tafseerRukuPlainText({
  required TafseerSurah surah,
  required TafseerRuku ruku,
  required String bodyHtml,
}) {
  final out = StringBuffer()
    ..writeln(surah.nameUrdu)
    ..writeln(ruku.eyebrow)
    ..writeln(ruku.titleUrdu);

  if (ruku.ayahBlock.isNotEmpty) {
    out
      ..writeln()
      ..writeln(ruku.ayahBlock);
  }

  final paragraphs = _paragraphs(bodyHtml);
  if (paragraphs.isNotEmpty) {
    out.writeln();
    for (final p in paragraphs) {
      out
        ..writeln(p)
        ..writeln();
    }
  }

  if (ruku.glossary.isNotEmpty) {
    out
      ..writeln('مشکل الفاظ اور اصطلاحاتِ فقر')
      ..writeln();
    for (final g in ruku.glossary) {
      out.writeln('${g.term}: ${stripHtml(g.definitionHtml)}');
    }
  }

  return out.toString().trimRight();
}

/// Body paragraphs in document order, tags removed.
List<String> _paragraphs(String html) {
  return RegExp(r'<p\b[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true)
      .allMatches(html)
      .map((m) => stripHtml(m.group(1) ?? ''))
      .where((p) => p.isNotEmpty)
      .toList();
}

/// Removes tags and collapses runs of whitespace, leaving the text intact.
///
/// Matches any tag regardless of its attributes — some sources tag their ayah
/// spans with extra data attributes, and those must not survive into the text.
String stripHtml(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(RegExp(r'[ \t]*\n[ \t]*'), ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}
