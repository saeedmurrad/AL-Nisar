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
2. Set `SURAH_ID` / `SURAH_NUMBER` / `SURAH_NAME_URDU` in that script and run:
   `python3 tool/tafseer_from_html.py <source.html> assets/tafseer`
   It rewrites `index.json` with only the surah it converted, so merge the new
   entry back into the existing list by hand.
3. Register the new folder in `pubspec.yaml` under `flutter: assets:`
   (`assets/tafseer/<id>/surah.json` and `assets/tafseer/<id>/rukus/`).
4. Push to `main` — GitHub Actions redeploys the web build.

Body HTML is rendered by `lib/widgets/tafseer_html.dart`. Keep the inline
`<span class="ayah">` (Quranic fragments, saffron Amiri) and `<span class="hl">`
(highlighted phrases, lapis) markup — those class selectors drive the styling.
