# Tafseer content

Bundled, offline commentary. Adding a surah is a file drop plus a redeploy —
there is no admin UI and nothing is stored in Firestore.

```
index.json              list of surahs shown on /tafseer
<id>/surah.json         masthead, preface, symbol key, ruku index + glossaries
<id>/rukus/NN.html      one ruku's body paragraphs, zero-padded
```

## Adding a surah

1. Author the page in the same HTML shape as the Surah Yusuf source (see the
   docstring in `tool/tafseer_from_html.py`).
2. Convert it:
   ```
   python3 tool/tafseer_from_html.py <source.html> assets/tafseer \
       --id raad --number 13 --name 'سورۂ رعد'
   ```
   The surah is merged into `index.json` — other surahs are preserved and the
   list stays sorted by surah number. Pass `--subtitle` to override the
   auto-generated index-card line.
3. Register the new folder in `pubspec.yaml` under `flutter: assets:`
   (`assets/tafseer/<id>/surah.json` and `assets/tafseer/<id>/rukus/`).
4. Push to `main` — GitHub Actions redeploys the web build.

Body HTML is rendered by `lib/widgets/tafseer_html.dart`. Keep the inline
`<span class="ayah">` (Quranic fragments, saffron Amiri) and `<span class="hl">`
(highlighted phrases, lapis) markup — those class selectors drive the styling.

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
