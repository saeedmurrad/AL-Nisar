import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme_colors.dart';
import '../theme/tafseer_theme.dart';

/// Nastaliq for Urdu prose, Amiri for Quranic text — matching the published
/// tafseer page. Both come from `google_fonts` (the project bundles no fonts).
String? get tafseerUrduFamily => GoogleFonts.notoNastaliqUrdu().fontFamily;
String? get tafseerArabicFamily => GoogleFonts.amiri().fontFamily;

/// Style map for the tafseer body HTML.
///
/// `.ayah` (inline Quranic fragments) and `.hl` (highlighted phrases) are class
/// selectors — supported by flutter_html via the `html` package's CSS matcher.
/// They are declared after `p`/`span` so they win the merge.
Map<String, Style> tafseerHtmlStyle(
  BuildContext context, {
  double fontSize = 16,
  double lineHeight = 2.35,
}) {
  final c = context.c;
  final lapisSoft = TafseerPalette.lapisSoft(context);

  return {
    'body': Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      backgroundColor: Colors.transparent,
      fontFamily: tafseerUrduFamily,
      fontSize: FontSize(fontSize),
      color: c.textPrimary,
      lineHeight: LineHeight(lineHeight),
      textAlign: TextAlign.right,
      direction: TextDirection.rtl,
    ),
    'p': Style(
      margin: Margins.only(bottom: 18),
      padding: HtmlPaddings.zero,
      fontFamily: tafseerUrduFamily,
      fontSize: FontSize(fontSize),
      color: c.textPrimary,
      lineHeight: LineHeight(lineHeight),
      textAlign: TextAlign.right,
      direction: TextDirection.rtl,
    ),
    'b': Style(fontWeight: FontWeight.w600, color: c.textPrimary),
    'strong': Style(fontWeight: FontWeight.w700, color: c.textPrimary),
    'em': Style(fontStyle: FontStyle.italic),
    'img': Style(display: Display.none),
    '.ayah': Style(
      fontFamily: tafseerArabicFamily,
      fontSize: FontSize(fontSize * 1.22),
      fontWeight: FontWeight.w700,
      color: c.accentGold,
      lineHeight: LineHeight(1.6),
    ),
    '.hl': Style(color: lapisSoft, fontWeight: FontWeight.w600),
  };
}

/// Renders a fragment of bundled tafseer HTML with the reading styles applied.
class TafseerHtml extends StatelessWidget {
  const TafseerHtml({
    super.key,
    required this.data,
    this.fontSize = 16,
    this.lineHeight = 2.35,
  });

  final String data;
  final double fontSize;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    return Html(
      data: data,
      shrinkWrap: true,
      style: tafseerHtmlStyle(
        context,
        fontSize: fontSize,
        lineHeight: lineHeight,
      ),
      onLinkTap: (url, attributes, element) {},
    );
  }
}

/// Splits a glossary definition into spans, honouring the only inline markup
/// the bundled content uses: `<b>`.
///
/// The definitions are short and 93% of them carry no markup at all, so
/// rendering each through the full HTML parser is wasted work — a ruku can hold
/// two dozen of them. Anything unexpected is degraded to plain text rather than
/// shown as raw tags.
List<TextSpan> tafseerInlineSpans(
  String html, {
  required TextStyle base,
  required TextStyle bold,
}) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r'<b>(.*?)</b>', caseSensitive: false, dotAll: true);
  var index = 0;

  void addPlain(String raw) {
    if (raw.isEmpty) return;
    final text = raw.replaceAll(RegExp(r'<[^>]+>'), '');
    if (text.isNotEmpty) spans.add(TextSpan(text: text, style: base));
  }

  for (final m in pattern.allMatches(html)) {
    addPlain(html.substring(index, m.start));
    final inner = (m.group(1) ?? '').replaceAll(RegExp(r'<[^>]+>'), '');
    if (inner.isNotEmpty) spans.add(TextSpan(text: inner, style: bold));
    index = m.end;
  }
  addPlain(html.substring(index));

  return spans;
}
