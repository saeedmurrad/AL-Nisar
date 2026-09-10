#!/usr/bin/env python3
"""Convert an authored tafseer HTML page into bundled app assets.

Usage:
    python3 tool/tafseer_from_html.py <source.html> assets/tafseer

The source page is expected to use the same markup as the Surah Yusuf page:

    header.masthead   > p.basmala, h1, p.sub, p.kicker
    div.preface       > p (one or more), ul.key > li > b (term) + meaning
    section.ruku[id]  > div.marker > span.eyebrow  ("<ordinal> · آیات <range>")
                        h2.ttl, p.ayah-block, p (body), aside.lughat > dl > dt/dd
    footer.colophon   > p

It writes <out>/index.json, <out>/<id>/surah.json and <out>/<id>/rukus/NN.html.
Body paragraphs are copied verbatim so the inline <span class="ayah"> and
<span class="hl"> markup keeps driving the reader's styling.

The surah id and name are currently hardcoded to Yusuf near the bottom of this
file — set SURAH_ID / SURAH_NAME_URDU / SURAH_NUMBER before running it on a new
page, then add the new entry to index.json (this script rewrites index.json with
only the surah it just converted).
"""

import json
import os
import re
import sys

SRC = sys.argv[1]
OUT = sys.argv[2]

SURAH_ID = "yusuf"
SURAH_NUMBER = 12
SURAH_NAME_URDU = "سورۂ یوسف"

html = open(SRC, encoding="utf-8").read()

# Only the document body matters; drop the <style> blocks.
html = re.sub(r"<style>.*?</style>", "", html, flags=re.S)


def one(pattern, text, flags=re.S):
    m = re.search(pattern, text, flags)
    return m.group(1).strip() if m else ""


def all_of(pattern, text, flags=re.S):
    return [m.strip() for m in re.findall(pattern, text, flags)]


# ---------------------------------------------------------------- masthead
masthead = one(r'<header class="masthead">(.*?)</header>', html)
basmala = one(r'<p class="basmala">(.*?)</p>', masthead)
title = one(r"<h1>(.*?)</h1>", masthead)
subtitle = one(r'<p class="sub">(.*?)</p>', masthead)
kicker = one(r'<p class="kicker">(.*?)</p>', masthead)

# ---------------------------------------------------------------- preface
preface = one(r'<div class="preface">(.*?)</div>', html)
preface_paras = ["<p>%s</p>" % p for p in all_of(r"<p>(.*?)</p>", preface)]
key = [
    {"term": t.strip(), "meaning": m.strip()}
    for t, m in re.findall(r"<li><b>(.*?)</b>(.*?)</li>", preface, re.S)
]

# ---------------------------------------------------------------- colophon
colophon = one(r'<footer class="colophon">\s*<p>(.*?)</p>', html)

# ---------------------------------------------------------------- rukus
rukus = []
bodies = {}
for block in all_of(r'(<section class="ruku".*?</section>)', html):
    number = int(one(r'id="r(\d+)"', block))
    eyebrow = one(r'<span class="eyebrow">(.*?)</span>', block)
    parts = [p.strip() for p in eyebrow.split("·")]
    ordinal = parts[0] if parts else ""
    ayah_range = re.sub(r"^آیات\s*", "", parts[1]) if len(parts) > 1 else ""

    ruku_title = one(r'<h2 class="ttl">(.*?)</h2>', block)
    ayah_block = one(r'<p class="ayah-block">(.*?)</p>', block)

    aside = one(r"<aside class=\"lughat\">(.*?)</aside>", block)
    glossary = [
        {"term": t.strip(), "definitionHtml": d.strip()}
        for t, d in re.findall(r"<dt>(.*?)</dt><dd>(.*?)</dd>", aside, re.S)
    ]

    # Body = the plain <p> elements, i.e. everything except the ayah-block and
    # the glossary aside. Keep the inline .ayah / .hl spans verbatim.
    without_aside = re.sub(r"<aside class=\"lughat\">.*?</aside>", "", block, flags=re.S)
    without_aside = re.sub(r'<p class="ayah-block">.*?</p>', "", without_aside, flags=re.S)
    paras = re.findall(r"(<p>.*?</p>)", without_aside, re.S)
    bodies[number] = "\n".join(p.strip() for p in paras) + "\n"

    rukus.append(
        {
            "number": number,
            "ordinalUrdu": ordinal,
            "ayahRangeUrdu": ayah_range,
            "titleUrdu": ruku_title,
            "ayahBlock": ayah_block,
            "glossary": glossary,
        }
    )

rukus.sort(key=lambda r: r["number"])

surah = {
    "id": SURAH_ID,
    "surahNumber": SURAH_NUMBER,
    "nameUrdu": SURAH_NAME_URDU,
    "titleUrdu": title,
    "basmala": basmala,
    "subtitleUrdu": subtitle,
    "kicker": kicker,
    "prefaceHtml": preface_paras,
    "key": key,
    "colophonHtml": colophon,
    "rukus": rukus,
}

index = [
    {
        "id": SURAH_ID,
        "surahNumber": SURAH_NUMBER,
        "nameUrdu": SURAH_NAME_URDU,
        "titleUrdu": title,
        "subtitleUrdu": "اشاری تفسیر · بارہ رکوع",
        "rukuCount": len(rukus),
        "isAvailable": True,
    }
]

os.makedirs(os.path.join(OUT, SURAH_ID, "rukus"), exist_ok=True)


def write(path, text):
    with open(os.path.join(OUT, path), "w", encoding="utf-8") as f:
        f.write(text)


write("index.json", json.dumps(index, ensure_ascii=False, indent=2) + "\n")
write(f"{SURAH_ID}/surah.json", json.dumps(surah, ensure_ascii=False, indent=2) + "\n")
for n, body in bodies.items():
    write("%s/rukus/%02d.html" % (SURAH_ID, n), body)

print("rukus:", len(rukus))
for r in rukus:
    print(
        "  %2d  %-14s %-10s glossary=%2d  body=%d chars"
        % (
            r["number"],
            r["ordinalUrdu"],
            r["ayahRangeUrdu"],
            len(r["glossary"]),
            len(bodies[r["number"]]),
        )
    )
print("key entries:", len(key), " preface paras:", len(preface_paras))
print("colophon:", bool(colophon), " basmala:", bool(basmala))
