# Tafseer content

Bundled, offline commentary. Adding a surah is a file drop plus a redeploy —
there is no admin UI and nothing is stored in Firestore.

```
index.json              list of surahs shown on /tafseer
<id>/surah.json         masthead, preface, symbol key, ruku index + glossaries
<id>/rukus/NN.html      one ruku's body paragraphs, zero-padded
```

Currently bundled, in surah order:

| # | id | surah | rukus |
|---|----|-------|-------|
| 12 | `yusuf` | سورۂ یوسف | 12 |
| 13 | `raad` | سورۂ رعد | 6 |
| 14 | `ibrahim` | سورۂ ابراہیم | 7 |
| 15 | `hijr` | سورۂ الحجر | 6 |
| 16 | `nahl` | سورۂ النحل | 16 |
| 17 | `bani-israel` | سورۂ بنی اسرائیل | 12 |
| 18 | `kahf` | سورۂ الکہف | 12 |
| 19 | `maryam` | سورۂ مریم | 6 |
| 20 | `taha` | سورۂ طٰہٰ | 8 |
| 21 | `anbiya` | سورۂ الانبیاء | 7 |
| 22 | `hajj` | سورۂ الحج | 10 |
| 23 | `muminun` | سورۂ المؤمنون | 6 |
| 24 | `nur` | سورۂ النور | 9 |
| 25 | `furqan` | سورۂ الفرقان | 6 |
| 26 | `shuara` | سورۂ الشعراء | 11 |
| 27 | `naml` | سورۂ النمل | 7 |
| 28 | `qasas` | سورۂ القصص | 9 |
| 29 | `ankabut` | سورۂ العنکبوت | 7 |
| 30 | `rum` | سورۂ الروم | 6 |
| 31 | `luqman` | سورۂ لقمان | 4 |
| 32 | `sajdah` | سورۂ السجدہ | 3 |
| 33 | `ahzab` | سورۂ الاحزاب | 9 |
| 34 | `saba` | سورۂ سبا | 6 |
| 35 | `fatir` | سورۂ فاطر | 5 |
| 36 | `yasin` | سورۂ یٰسٓ | 5 |
| 37 | `saffat` | سورۂ الصّٰفّٰت | 5 |
| 38 | `sad` | سورۂ صٓ | 5 |
| 39 | `zumar` | سورۂ الزمر | 8 |
| 40 | `ghafir` | سورۂ غافر (المؤمن) | 9 |
| 41 | `fussilat` | سورۂ حٰمٓ السجدہ (فصلت) | 6 |
| 42 | `shura` | سورۂ الشوریٰ | 5 |
| 43 | `zukhruf` | سورۂ الزخرف | 7 |
| 44 | `dukhan` | سورۂ الدخان | 3 |
| 45 | `jathiya` | سورۂ الجاثیہ | 4 |
| 46 | `ahqaf` | سورۂ الاحقاف | 4 |
| 47 | `muhammad` | سورۂ محمد | 4 |
| 48 | `fath` | سورۂ الفتح | 4 |
| 49 | `hujurat` | سورۂ الحجرات | 2 |
| 50 | `qaf` | سورۂ قٓ | 3 |
| 51 | `dhariyat` | سورۂ الذاریات | 3 |
| 52 | `tur` | سورۂ الطور | 2 |
| 53 | `najm` | سورۂ النجم | 3 |
| 54 | `qamar` | سورۂ القمر | 3 |
| 55 | `rahman` | سورۂ الرحمٰن | 3 |
| 56 | `waqiah` | سورۂ الواقعہ | 3 |
| 57 | `hadid` | سورۂ الحدید | 4 |
| 58 | `mujadilah` | سورۂ المجادلہ | 3 |
| 59 | `hashr` | سورۂ الحشر | 3 |
| 60 | `mumtahanah` | سورۂ الممتحنہ | 2 |
| 61 | `saff` | سورۂ الصف | 2 |
| 62 | `jumuah` | سورۂ الجمعہ | 2 |
| 63 | `munafiqun` | سورۂ المنافقون | 2 |
| 64 | `taghabun` | سورۂ التغابن | 2 |
| 65 | `talaq` | سورۂ الطلاق | 2 |
| 66 | `tahrim` | سورۂ التحریم | 2 |
| 67 | `mulk` | سورۂ الملک | 2 |
| 68 | `qalam` | سورۂ القلم | 2 |
| 69 | `haqqah` | سورۂ الحاقہ | 2 |
| 70 | `maarij` | سورۂ المعارج | 2 |
| 71 | `nuh` | سورۂ نوح | 2 |
| 72 | `jinn` | سورۂ الجن | 2 |
| 73 | `muzzammil` | سورۂ المزمل | 2 |
| 74 | `muddaththir` | سورۂ المدثر | 2 |
| 75 | `qiyamah` | سورۂ القیامہ | 2 |
| 76 | `dahr` | سورۂ الدہر | 2 |
| 77 | `mursalat` | سورۂ المرسلات | 2 |
| 78 | `naba` | سورۂ النبا | 2 |
| 79 | `naziat` | سورۂ النازعات | 2 |
| 80 | `abasa` | سورۂ عبس | 1 |
| 81 | `takwir` | سورۂ التکویر | 1 |
| 82 | `infitar` | سورۂ الانفطار | 1 |
| 83 | `mutaffifin` | سورۂ المطففین | 1 |
| 84 | `inshiqaq` | سورۂ الانشقاق | 1 |
| 85 | `buruj` | سورۂ البروج | 1 |
| 86 | `tariq` | سورۂ الطارق | 1 |
| 87 | `ala` | سورۂ الاعلیٰ | 1 |
| 88 | `ghashiyah` | سورۂ الغاشیہ | 1 |

## Adding a surah

1. Author the page in the same HTML shape as the Surah Yusuf source (see the
   docstring in `tool/tafseer_from_html.py`).
2. Convert it:
   ```
   python3 tool/tafseer_from_html.py <source.html> assets/tafseer \
       --id raad --number 13 --name 'سورۂ رعد'
   ```
   The surah is merged into `index.json` — other surahs are preserved and the
   list stays sorted by surah number.
3. Register the new folder in `pubspec.yaml` under `flutter: assets:`
   (`assets/tafseer/<id>/surah.json` and `assets/tafseer/<id>/rukus/`).
4. Add a row to the `bundled` table in `test/tafseer_bundled_service_test.dart`
   (id, surah number, Urdu name, ruku count, first and last ruku titles) so a
   malformed source page fails the build instead of shipping empty rukus.
5. Push to `main` — GitHub Actions redeploys the web build.

Only `prefaceHtml`, `colophonHtml`, the glossary definitions and the ruku body
files keep their HTML. Every other field — basmala, titles, ayah blocks,
eyebrows, key and glossary terms — is stripped to plain text by the converter,
because the reader renders those with a `Text` widget and any surviving tag
would show up literally on screen. Surah Bani Israel wraps some ayah blocks in
`<span class="ayah" data-a="N">`, which is what surfaced this.

Body HTML is rendered by `lib/widgets/tafseer_html.dart`. Keep the inline
`<span class="ayah">` (Quranic fragments, saffron Amiri) and `<span class="hl">`
(highlighted phrases, lapis) markup — those class selectors drive the styling.

## Search

`lib/services/tafseer_search_service.dart` indexes every bundled surah on the
first query — ayah blocks, inline ayah fragments, prose paragraphs, glossary
entries and ruku titles — and the Tafseer screen searches across all of them.

Matching runs on folded text (`lib/utils/arabic_search_text.dart`): diacritics
and tatweel are stripped, alef/yeh/kaf/heh variants are folded together, and
Urdu and Arabic digits map to Western, so `نحن نقص` finds `نَحْنُ نَقُصُّ`.
Do-chashmi heh is deliberately *not* folded — doing so would make بھائی match
بہائی. The fold records an index map back to the original text, which is what
lets a hit be highlighted in the right place.

Adding a surah needs no search work: the index is built from `index.json`.

## Print edition

`tool/tafseer_print_pdf.py` builds a print-ready PDF from these same assets, so
it can never drift from what the app shows:

```
python3 tool/tafseer_print_pdf.py --out build/tafseer-print.pdf
python3 tool/tafseer_print_pdf.py --surah raad --out build/raad.pdf
```

A4, pure black on white (no tinted panels — structure is carried by weight and
rules), one ruku per page, numbered footers. Amiri and Noto Nastaliq Urdu are
embedded as data URIs and the script *fails* if Nastaliq is missing from the
output: without it Chrome silently substitutes a naskh system font and the Urdu
prints in the wrong script.

Page numbers come from Chrome's `Page.printToPDF` footer template, which the
`--print-to-pdf` command-line flag cannot do — hence the small CDP driver in
`tool/chrome_print.mjs` (Node >= 22, no npm dependencies).
