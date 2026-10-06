import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/models/tafseer_models.dart';
import 'package:spiritual_learning_app/utils/tafseer_print_html.dart';

TafseerSurah _load(String id) => TafseerSurah.fromJson(
  jsonDecode(File('assets/tafseer/$id/surah.json').readAsStringSync())
      as Map<String, dynamic>,
);

Map<int, String> _bodies(TafseerSurah surah) => {
  for (final r in surah.rukus)
    r.number: File(
      'assets/tafseer/${surah.id}/rukus/'
      '${r.number.toString().padLeft(2, '0')}.html',
    ).readAsStringSync(),
};

void main() {
  // Three rukus, so the whole document stays small enough to reason about.
  final dukhan = _load('dukhan');
  final html = tafseerPrintHtml(surah: dukhan, rukuBodies: _bodies(dukhan));

  test('document is standalone, RTL and titled for the surah', () {
    expect(html, startsWith('<!doctype html>'));
    expect(html, contains('lang="ur" dir="rtl"'));
    expect(html, contains('<title>تفسیرِ ابنِ عربی — سورۂ الدخان</title>'));
    expect(html, endsWith('</body></html>'));
  });

  test('prints in black ink only — no palette colour survives', () {
    // The reading theme's saffron, lapis and tinted paper must not reach paper.
    for (final hex in const [
      '#B07A12',
      '#D5A63A',
      '#E0B04A',
      '#1E3A8A',
      '#3B5BB5',
      '#9FB4F2',
      '#EFE8D6',
      '#E6DDC6',
      '#E7DFC9',
    ]) {
      expect(
        html.toUpperCase(),
        isNot(contains(hex)),
        reason: '$hex leaked into the print stylesheet',
      );
    }
    expect(html, contains('background: #fff; color: #000;'));
    // Structure is carried by rules, not fills.
    expect(html, isNot(contains('background: var(')));
  });

  test('loads Nastaliq and Amiri webfonts', () {
    expect(html, contains('fonts.googleapis.com'));
    expect(html, contains('Noto+Nastaliq+Urdu'));
    expect(html, contains('family=Amiri'));
    expect(html, contains('display=block'));
  });

  test('carries the full front matter', () {
    expect(html, contains(dukhan.basmala));
    expect(html, contains(dukhan.nameUrdu));
    expect(html, contains(dukhan.subtitleUrdu));
    expect(html, contains(dukhan.kicker));
    for (final p in dukhan.prefaceHtml) {
      expect(html, contains(p));
    }
    for (final k in dukhan.key) {
      expect(html, contains('<b>${k.term}</b> ${k.meaning}'));
    }
    expect(html, contains(dukhan.colophonHtml));
  });

  test('indexes every ruku with Urdu numerals', () {
    expect(html, contains('فہرستِ رکوع'));
    for (final (i, r) in dukhan.rukus.indexed) {
      final n = const ['۱', '۲', '۳'][i];
      expect(html, contains('<span class="n">$n</span>'));
      expect(html, contains('<span>${r.titleUrdu}</span>'));
    }
  });

  test('carries every ruku whole: marker, title, body and glossary', () {
    expect('<section class="ruku">'.allMatches(html).length, 3);
    final bodies = _bodies(dukhan);
    for (final r in dukhan.rukus) {
      expect(html, contains('<h2 class="ttl">${r.titleUrdu}</h2>'));
      expect(html, contains(r.eyebrow));
      expect(html, contains('<p class="ayah-block">${r.ayahBlock}</p>'));
      // The body HTML is inlined verbatim, inline ayah spans and all.
      expect(html, contains(bodies[r.number]!.trim()));
      for (final g in r.glossary) {
        expect(
          html,
          contains('<dt>${g.term}</dt><dd>${g.definitionHtml}</dd>'),
        );
      }
    }
    expect(
      'مشکل الفاظ اور اصطلاحاتِ فقر'.allMatches(html).length,
      3,
      reason: 'one glossary heading per ruku',
    );
  });

  test('inline ayah spans reach the page and are styled for print', () {
    expect(html, contains('class="ayah"'));
    expect(html, contains('.ayah { font-family: Amiri, serif;'));
    // Lapis highlights degrade to bold rather than vanishing.
    expect(html, contains('.hl { font-weight: 700; }'));
  });

  test('breaks pages between rukus and keeps headings with their text', () {
    expect(html, contains('section.ruku { break-before: page; }'));
    expect(html, contains('@page { size: A4;'));
    expect(html, contains('break-after: avoid'));
    expect(html, contains('orphans: 2; widows: 2;'));
  });

  test('a missing ruku body still prints that ruku', () {
    final partial = tafseerPrintHtml(
      surah: dukhan,
      rukuBodies: {..._bodies(dukhan)}..remove(2),
    );
    expect('<section class="ruku">'.allMatches(partial).length, 3);
    expect(
      partial,
      contains('<h2 class="ttl">${dukhan.rukus[1].titleUrdu}</h2>'),
    );
  });

  test('escapes plain-text fields without touching the HTML ones', () {
    final surah = TafseerSurah(
      id: 'x',
      surahNumber: 1,
      nameUrdu: '<script>a & b',
      titleUrdu: 't',
      basmala: 'b',
      subtitleUrdu: 's',
      kicker: 'k',
      prefaceHtml: const ['<p>kept <b>as</b> markup</p>'],
      key: const [],
      colophonHtml: 'end<br>line',
      rukus: const [],
    );
    final out = tafseerPrintHtml(surah: surah, rukuBodies: const {});
    expect(out, contains('&lt;script&gt;a &amp; b'));
    expect(out, isNot(contains('<script>')));
    expect(out, contains('<p>kept <b>as</b> markup</p>'));
    expect(out, contains('end<br>line'));
  });
}
