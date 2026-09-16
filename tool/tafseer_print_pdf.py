#!/usr/bin/env python3
"""Build a print-ready PDF from the bundled tafseer assets.

Usage:
    python3 tool/tafseer_print_pdf.py --out build/tafseer-print.pdf
    python3 tool/tafseer_print_pdf.py --surah raad --out build/raad.pdf

Reads assets/tafseer/ (the same files the app ships), lays the content out for
A4, and prints it through headless Chrome with a numbered footer. Output is pure black on white: no
saffron, no lapis, no tinted panels — structure is carried by weight, size and
rules instead of colour, so it stays legible on a mono laser printer.

Amiri and Noto Nastaliq Urdu are embedded as data URIs. Without that Chrome
silently substitutes a naskh system font (Geeza Pro) for Nastaliq and the Urdu
comes out in the wrong script. The fonts are cached under build/.tafseer-fonts/
and downloaded once if missing.
"""

import argparse
import base64
import json
import os
import shutil
import socket
import subprocess
import sys
import time
import urllib.request

ASSETS = "assets/tafseer"
FONT_CACHE = "build/.tafseer-fonts"

FONT_URLS = {
    "amiri-400.ttf": "https://fonts.gstatic.com/s/amiri/v30/J7aRnpd8CGxBHqUp.ttf",
    "amiri-700.ttf": "https://fonts.gstatic.com/s/amiri/v30/J7acnpd8CGxBHp2VkZY4.ttf",
    "nastaliq-400.ttf": "https://fonts.gstatic.com/s/notonastaliqurdu/v23/LhWNMUPbN-oZdNFcBy1-DJYsEoTq5pudQ9L940pGPkB3Qjj5DK0.ttf",
    "nastaliq-700.ttf": "https://fonts.gstatic.com/s/notonastaliqurdu/v23/LhWNMUPbN-oZdNFcBy1-DJYsEoTq5pudQ9L940pGPkB3Qt_-DK0.ttf",
}

CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
]


def urdu_digits(value):
    digits = "۰۱۲۳۴۵۶۷۸۹"
    return "".join(digits[int(c)] if c.isdigit() else c for c in str(value))


def find_chrome():
    for p in CHROME_CANDIDATES:
        if os.path.exists(p):
            return p
    found = shutil.which("google-chrome") or shutil.which("chromium")
    if found:
        return found
    sys.exit("No Chrome/Chromium found; install one or edit CHROME_CANDIDATES.")


def font_data_uris():
    os.makedirs(FONT_CACHE, exist_ok=True)
    out = {}
    for name, url in FONT_URLS.items():
        path = os.path.join(FONT_CACHE, name)
        if not os.path.exists(path) or os.path.getsize(path) < 10000:
            print("downloading %s" % name)
            urllib.request.urlretrieve(url, path)
        with open(path, "rb") as f:
            blob = f.read()
        if blob[:4] != b"\x00\x01\x00\x00":
            sys.exit("%s is not a TrueType file — delete %s and retry" % (name, path))
        out[name] = base64.b64encode(blob).decode("ascii")
    return out


# Print stylesheet: black ink on white, no filled panels.
CSS = """
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
"""


def render_surah(surah):
    rukus = surah["rukus"]
    parts = ['<div class="surah">']
    parts.append(
        '<header class="masthead">'
        '<p class="basmala">%s</p><h1>%s</h1>'
        '<p class="surah-name">%s</p><p class="sub">%s</p><p class="kicker">%s</p>'
        "</header>"
        % (
            surah["basmala"],
            surah["titleUrdu"],
            surah["nameUrdu"],
            surah["subtitleUrdu"],
            surah["kicker"],
        )
    )

    parts.append('<div class="preface">')
    parts.extend(surah["prefaceHtml"])
    if surah["key"]:
        parts.append('<ul class="key">')
        parts.extend(
            "<li><b>%s</b> %s</li>" % (k["term"], k["meaning"]) for k in surah["key"]
        )
        parts.append("</ul>")
    parts.append("</div>")

    parts.append('<nav class="toc"><h2>فہرستِ رکوع</h2><ol>')
    for r in rukus:
        parts.append(
            '<li><span class="n">%s</span><span>%s</span>'
            '<span class="rng">%s</span></li>'
            % (urdu_digits(r["number"]), r["titleUrdu"], r["ayahRangeUrdu"])
        )
    parts.append("</ol></nav>")

    for r in rukus:
        body = open(
            os.path.join(ASSETS, surah["id"], "rukus", "%02d.html" % r["number"]),
            encoding="utf-8",
        ).read()
        eyebrow = r["ordinalUrdu"]
        if r["ayahRangeUrdu"]:
            eyebrow += " · آیات " + r["ayahRangeUrdu"]
        parts.append('<section class="ruku">')
        parts.append(
            '<div class="marker"><span class="ayn">ع</span>'
            '<span class="eyebrow">%s</span><span class="rule"></span></div>' % eyebrow
        )
        parts.append('<h2 class="ttl">%s</h2>' % r["titleUrdu"])
        if r["ayahBlock"]:
            parts.append('<p class="ayah-block">%s</p>' % r["ayahBlock"])
        parts.append(body)
        if r["glossary"]:
            parts.append(
                '<aside class="lughat"><h3>مشکل الفاظ اور اصطلاحاتِ فقر</h3><dl>'
            )
            parts.extend(
                "<dt>%s</dt><dd>%s</dd>" % (g["term"], g["definitionHtml"])
                for g in r["glossary"]
            )
            parts.append("</dl></aside>")
        parts.append("</section>")

    if surah["colophonHtml"]:
        parts.append('<footer class="colophon"><p>%s</p></footer>' % surah["colophonHtml"])
    parts.append("</div>")
    return "".join(parts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="build/tafseer-print.pdf")
    ap.add_argument("--surah", action="append", help="surah id; repeatable. default: all")
    args = ap.parse_args()

    index = json.load(open(os.path.join(ASSETS, "index.json"), encoding="utf-8"))
    ids = args.surah or [e["id"] for e in index]
    surahs = []
    for sid in ids:
        path = os.path.join(ASSETS, sid, "surah.json")
        if not os.path.exists(path):
            sys.exit("no bundled surah with id %r" % sid)
        surahs.append(json.load(open(path, encoding="utf-8")))

    fonts = font_data_uris()
    faces = "".join(
        '@font-face{font-family:"%s";font-style:normal;font-weight:%d;'
        'font-display:block;src:url(data:font/ttf;base64,%s) format("truetype");}'
        % (fam, wt, fonts[f])
        for fam, wt, f in [
            ("Noto Nastaliq Urdu", 400, "nastaliq-400.ttf"),
            ("Noto Nastaliq Urdu", 700, "nastaliq-700.ttf"),
            ("Amiri", 400, "amiri-400.ttf"),
            ("Amiri", 700, "amiri-700.ttf"),
        ]
    )

    html = (
        '<!doctype html><html lang="ur" dir="rtl"><head><meta charset="utf-8">'
        "<title>تفسیرِ ابنِ عربی</title><style>%s%s</style></head><body>%s</body></html>"
        % (faces, CSS, "".join(render_surah(s) for s in surahs))
    )

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    src = os.path.abspath(args.out) + ".html"
    with open(src, "w", encoding="utf-8") as f:
        f.write(html)

    out = os.path.abspath(args.out)
    if os.path.exists(out):
        os.remove(out)
    profile = os.path.join(FONT_CACHE, "chrome-profile")
    shutil.rmtree(profile, ignore_errors=True)

    # Page numbers need Page.printToPDF's footerTemplate, which the
    # --print-to-pdf CLI flag does not expose, so drive Chrome over the
    # DevTools protocol instead (tool/chrome_print.mjs).
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]

    chrome = subprocess.Popen(
        [
            find_chrome(),
            "--headless=new", "--disable-gpu", "--no-sandbox", "--disable-extensions",
            "--user-data-dir=" + profile,
            "--remote-debugging-port=%d" % port,
            "--remote-allow-origins=*",
            "about:blank",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        node = subprocess.run(
            ["node", "tool/chrome_print.mjs", str(port), "file://" + src, out],
            capture_output=True,
            text=True,
            timeout=300,
        )
    finally:
        chrome.terminate()
        try:
            chrome.wait(timeout=10)
        except subprocess.TimeoutExpired:
            chrome.kill()

    if node.returncode != 0 or not os.path.exists(out):
        sys.stderr.write(node.stdout + node.stderr)
        sys.exit("Chrome/CDP failed to produce a PDF")
    os.remove(src)

    # Fail loudly if Nastaliq was substituted rather than embedded.
    blob = open(out, "rb").read()
    import re as _re

    names = sorted(set(m.decode("latin1") for m in _re.findall(rb"/BaseFont\s*/([A-Za-z0-9+\-]+)", blob)))
    counts = [int(m) for m in _re.findall(rb"/Count\s+(\d+)", blob)]
    print("surahs:", ", ".join(s["id"] for s in surahs))
    print("fonts embedded:", names)
    print("pages:", max(counts) if counts else "?")
    print("size: %.1f MB" % (len(blob) / 1e6))
    print("written:", out)
    if not any("Nastaliq" in n for n in names):
        sys.exit("ERROR: Nastaliq was not embedded — Urdu would print in the wrong script")


if __name__ == "__main__":
    main()
