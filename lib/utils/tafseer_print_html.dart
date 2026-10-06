import '../models/tafseer_models.dart';
import 'urdu_digits.dart';

/// Builds a standalone, print-ready HTML document for one whole surah.
///
/// Pure black on white: no saffron, no lapis, no tinted panels — structure is
/// carried by weight, size and rules instead of colour, so the pages stay
/// legible on a mono laser printer and do not burn colour ink.
///
/// This is deliberately the same layout `tool/tafseer_print_pdf.py` produces
/// offline, so the in-app Print button and the generated PDFs stay in step.
/// Keep the two stylesheets in sync when either changes.
///
/// [rukuBodies] maps a ruku number to its bundled body HTML. A ruku whose body
/// is missing still prints its marker, title and glossary rather than aborting
/// the whole document.
String tafseerPrintHtml({
  required TafseerSurah surah,
  required Map<int, String> rukuBodies,
}) {
  final title = '${surah.titleUrdu} — ${surah.nameUrdu}';
  return '<!doctype html><html lang="ur" dir="rtl"><head>'
      '<meta charset="utf-8">'
      '<title>${_esc(title)}</title>'
      '$_fontsLink'
      '<style>$_printCss</style>'
      '</head><body>${_renderSurah(surah, rukuBodies)}</body></html>';
}

/// Nastaliq must come from a real webfont: without it the browser silently
/// substitutes a naskh system font and the Urdu prints in the wrong script.
const _fontsLink =
    '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
    'family=Amiri:wght@400;700&'
    'family=Noto+Nastaliq+Urdu:wght@400;700&display=block">';

String _renderSurah(TafseerSurah surah, Map<int, String> bodies) {
  final out = StringBuffer('<div class="surah">');

  out.write(
    '<header class="masthead">'
    '<p class="basmala">${_esc(surah.basmala)}</p>'
    '<h1>${_esc(surah.titleUrdu)}</h1>'
    '<p class="surah-name">${_esc(surah.nameUrdu)}</p>'
    '<p class="sub">${_esc(surah.subtitleUrdu)}</p>'
    '<p class="kicker">${_esc(surah.kicker)}</p>'
    '</header>',
  );

  out.write('<div class="preface">');
  out.writeAll(surah.prefaceHtml);
  if (surah.key.isNotEmpty) {
    out.write('<ul class="key">');
    for (final k in surah.key) {
      out.write('<li><b>${_esc(k.term)}</b> ${_esc(k.meaning)}</li>');
    }
    out.write('</ul>');
  }
  out.write('</div>');

  out.write('<nav class="toc"><h2>فہرستِ رکوع</h2><ol>');
  for (final r in surah.rukus) {
    out.write(
      '<li><span class="n">${toUrduDigits(r.number)}</span>'
      '<span>${_esc(r.titleUrdu)}</span>'
      '<span class="rng">${_esc(r.ayahRangeUrdu)}</span></li>',
    );
  }
  out.write('</ol></nav>');

  for (final r in surah.rukus) {
    out.write(
      '<section class="ruku">'
      '<div class="marker"><span class="ayn">ع</span>'
      '<span class="eyebrow">${_esc(r.eyebrow)}</span>'
      '<span class="rule"></span></div>'
      '<h2 class="ttl">${_esc(r.titleUrdu)}</h2>',
    );
    if (r.ayahBlock.isNotEmpty) {
      out.write('<p class="ayah-block">${_esc(r.ayahBlock)}</p>');
    }
    out.write(bodies[r.number] ?? '');
    if (r.glossary.isNotEmpty) {
      out.write(
        '<aside class="lughat"><h3>مشکل الفاظ اور اصطلاحاتِ فقر</h3><dl>',
      );
      for (final g in r.glossary) {
        out.write('<dt>${_esc(g.term)}</dt><dd>${g.definitionHtml}</dd>');
      }
      out.write('</dl></aside>');
    }
    out.write('</section>');
  }

  if (surah.colophonHtml.isNotEmpty) {
    out.write('<footer class="colophon"><p>${surah.colophonHtml}</p></footer>');
  }

  out.write('</div>');
  return out.toString();
}

/// Escapes a plain-text field. The bundled HTML fields — preface, glossary
/// definitions, colophon and the ruku bodies — are written through untouched,
/// because their markup is what carries the inline ayah and highlight spans.
String _esc(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

const _printCss = r'''
@page { size: A4; margin: 18mm 16mm 16mm; }
* { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
html { direction: rtl; }
body {
  background: #fff; color: #000; margin: 0;
  font-family: "Noto Nastaliq Urdu", serif;
  font-size: 11.5pt; line-height: 2.25;
}
.surah { break-before: page; }
.surah:first-of-type { break-before: auto; }

header.masthead { text-align: center; padding: 0 0 14pt; border-bottom: 1pt solid #000; }
.basmala { font-family: Amiri, serif; font-size: 19pt; line-height: 1.8; margin: 0 0 8pt; }
h1 { font-size: 24pt; font-weight: 700; line-height: 1.9; margin: 0; }
.surah-name { font-size: 15pt; font-weight: 700; margin: 8pt 0 0; }
.sub { font-size: 10.5pt; margin: 8pt 0 0; line-height: 2.1; }
.kicker { font-size: 8.5pt; letter-spacing: .06em; margin: 8pt 0 0; }

.preface { margin: 16pt 0 0; padding: 0 12pt 0 0; border-right: 2pt solid #000; }
.preface p { margin: 0 0 9pt; }
.key { margin: 12pt 0 0; padding: 0; list-style: none;
       columns: 2; column-gap: 20pt; font-size: 10pt; }
.key li { break-inside: avoid; margin: 0 0 2pt; }
.key b { font-weight: 700; }

nav.toc { margin: 18pt 0 0; border-top: 1pt solid #000; border-bottom: 1pt solid #000; padding: 8pt 0; }
nav.toc h2 { font-size: 11pt; font-weight: 700; margin: 0 0 4pt; }
nav.toc ol { margin: 0; padding: 0; list-style: none; }
nav.toc li { display: flex; gap: 8pt; align-items: baseline; padding: 1pt 0; font-size: 10.5pt; }
nav.toc .n { font-family: Amiri, serif; min-width: 16pt; text-align: center; }
nav.toc .rng { margin-inline-start: auto; font-family: Amiri, serif; font-size: 9.5pt; }

section.ruku { break-before: page; }
.marker { display: flex; align-items: center; gap: 10pt; margin: 0 0 4pt; }
.marker .ayn { font-family: Amiri, serif; font-size: 14pt; border: 1pt solid #000;
               border-radius: 50%; width: 24pt; height: 24pt; display: grid;
               place-items: center; line-height: 1; flex: none; }
.marker .eyebrow { font-size: 9pt; letter-spacing: .03em; }
.marker .rule { flex: 1; height: 1pt; background: #000; }
h2.ttl { font-size: 17pt; font-weight: 700; line-height: 2; margin: 0 0 10pt; }
.ayah-block { font-family: Amiri, serif; font-size: 15pt; font-weight: 700;
              text-align: center; line-height: 2; margin: 4pt 0 14pt; }
p { margin: 0 0 11pt; orphans: 2; widows: 2; }
.ayah { font-family: Amiri, serif; font-size: 1.2em; font-weight: 700; line-height: 1.6; padding: 0 .15em; }
.hl { font-weight: 700; }

aside.lughat { margin: 18pt 0 0; padding: 10pt 0 0; border-top: 1.5pt solid #000; }
aside.lughat h3 { font-size: 11.5pt; font-weight: 700; margin: 0 0 6pt; }
aside.lughat dl { margin: 0; display: grid; grid-template-columns: max-content 1fr;
                  gap: 1pt 12pt; font-size: 10pt; line-height: 2; }
aside.lughat dt { font-weight: 700; white-space: nowrap; break-after: avoid; }
aside.lughat dd { margin: 0; break-before: avoid; }

footer.colophon { break-before: page; margin-top: 18pt; border-top: 1pt solid #000;
                  padding-top: 10pt; font-size: 10pt; text-align: center; line-height: 2.1; }

h1, h2.ttl, aside.lughat h3, .marker, .ayah-block { break-after: avoid; }
.preface, nav.toc li { break-inside: avoid; }
''';
