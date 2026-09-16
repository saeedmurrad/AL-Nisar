#!/usr/bin/env python3
"""Convert an authored tafseer HTML page into bundled app assets.

Usage:
    python3 tool/tafseer_from_html.py <source.html> <out-dir> \
        --id raad --number 13 --name "سورۂ رعد"

The source page is expected to use the same markup as the Surah Yusuf page:

    header.masthead   > p.basmala, h1, p.sub, p.kicker
    div.preface       > p (one or more), ul.key > li > b (term) + meaning
    section.ruku[id]  > div.marker > span.eyebrow  ("<ordinal> · آیات <range>")
                        h2.ttl, p.ayah-block, p (body), aside.lughat > dl > dt/dd
    footer.colophon   > p

It writes <out>/<id>/surah.json and <out>/<id>/rukus/NN.html, and *merges* the
surah into <out>/index.json — replacing any entry with the same id and keeping
the list ordered by surah number.

Body paragraphs are copied verbatim so the inline <span class="ayah"> and
<span class="hl"> markup keeps driving the reader's styling.

Remember to register the new folder in pubspec.yaml under `flutter: assets:`.
"""

import argparse
import json
import os
import re


def urdu_digits(value):
    digits = "۰۱۲۳۴۵۶۷۸۹"
    return "".join(digits[int(c)] if c.isdigit() else c for c in str(value))


def one(pattern, text, flags=re.S):
    m = re.search(pattern, text, flags)
    return m.group(1).strip() if m else ""


def all_of(pattern, text, flags=re.S):
    return [m.strip() for m in re.findall(pattern, text, flags)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("out")
    ap.add_argument("--id", required=True, help="folder/route id, e.g. 'raad'")
    ap.add_argument("--number", required=True, type=int, help="surah number")
    ap.add_argument("--name", required=True, help="Urdu surah name")
    args = ap.parse_args()

    html = open(args.source, encoding="utf-8").read()
    html = re.sub(r"<style>.*?</style>", "", html, flags=re.S)

    # ---- masthead
    masthead = one(r'<header class="masthead">(.*?)</header>', html)
    basmala = one(r'<p class="basmala">(.*?)</p>', masthead)
    title = one(r"<h1>(.*?)</h1>", masthead)
    subtitle = one(r'<p class="sub">(.*?)</p>', masthead)
    kicker = one(r'<p class="kicker">(.*?)</p>', masthead)

    # ---- preface + symbol key
    preface = one(r'<div class="preface">(.*?)</div>', html)
    preface_paras = ["<p>%s</p>" % p for p in all_of(r"<p>(.*?)</p>", preface)]
    key = [
        {"term": t.strip(), "meaning": m.strip()}
        for t, m in re.findall(r"<li><b>(.*?)</b>(.*?)</li>", preface, re.S)
    ]

    colophon = one(r'<footer class="colophon">\s*<p>(.*?)</p>', html)

    # ---- rukus
    rukus, bodies = [], {}
    for block in all_of(r'(<section class="ruku".*?</section>)', html):
        number = int(one(r'id="r(\d+)"', block))
        eyebrow = one(r'<span class="eyebrow">(.*?)</span>', block)
        parts = [p.strip() for p in eyebrow.split("·")]
        ordinal = parts[0] if parts else ""
        ayah_range = re.sub(r"^آیات\s*", "", parts[1]) if len(parts) > 1 else ""

        aside = one(r'<aside class="lughat">(.*?)</aside>', block)
        glossary = [
            {"term": t.strip(), "definitionHtml": d.strip()}
            for t, d in re.findall(r"<dt>(.*?)</dt>\s*<dd>(.*?)</dd>", aside, re.S)
        ]

        # Body = the plain <p> elements: everything but the ayah block and aside.
        rest = re.sub(r'<aside class="lughat">.*?</aside>', "", block, flags=re.S)
        rest = re.sub(r'<p class="ayah-block">.*?</p>', "", rest, flags=re.S)
        bodies[number] = "\n".join(all_of(r"(<p>.*?</p>)", rest)) + "\n"

        rukus.append(
            {
                "number": number,
                "ordinalUrdu": ordinal,
                "ayahRangeUrdu": ayah_range,
                "titleUrdu": one(r'<h2 class="ttl">(.*?)</h2>', block),
                "ayahBlock": one(r'<p class="ayah-block">(.*?)</p>', block),
                "glossary": glossary,
            }
        )

    rukus.sort(key=lambda r: r["number"])

    surah = {
        "id": args.id,
        "surahNumber": args.number,
        "nameUrdu": args.name,
        "titleUrdu": title,
        "basmala": basmala,
        "subtitleUrdu": subtitle,
        "kicker": kicker,
        "prefaceHtml": preface_paras,
        "key": key,
        "colophonHtml": colophon,
        "rukus": rukus,
    }

    # ---- merge into the index rather than overwrite it
    index_path = os.path.join(args.out, "index.json")
    try:
        with open(index_path, encoding="utf-8") as f:
            index = [e for e in json.load(f) if e.get("id") != args.id]
    except (FileNotFoundError, ValueError):
        index = []
    index.append(
        {
            "id": args.id,
            "surahNumber": args.number,
            "nameUrdu": args.name,
            "titleUrdu": title,
            "subtitleUrdu": "اشاری تفسیر · %s رکوع" % urdu_digits(len(rukus)),
            "rukuCount": len(rukus),
            "isAvailable": True,
        }
    )
    index.sort(key=lambda e: e.get("surahNumber", 0))

    # ---- write
    os.makedirs(os.path.join(args.out, args.id, "rukus"), exist_ok=True)

    def write(rel, text):
        with open(os.path.join(args.out, rel), "w", encoding="utf-8") as f:
            f.write(text)

    write("index.json", json.dumps(index, ensure_ascii=False, indent=2) + "\n")
    write(
        "%s/surah.json" % args.id,
        json.dumps(surah, ensure_ascii=False, indent=2) + "\n",
    )
    for n, body in bodies.items():
        write("%s/rukus/%02d.html" % (args.id, n), body)

    print("surah: %s (#%d) %s" % (args.id, args.number, args.name))
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
    print("index now lists:", [e["id"] for e in index])


if __name__ == "__main__":
    main()
