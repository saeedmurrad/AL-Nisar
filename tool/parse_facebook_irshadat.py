#!/usr/bin/env python3
"""Parse Irshadat from Facebook HTML export (posts with سائیں جی کا فرمانِ مبارک)."""

from __future__ import annotations

import html
import json
import re
import sys
from datetime import datetime
from pathlib import Path

MARKER = 'سائیں جی کا فرمانِ مبارک'
SPEAKER = 'صوفی نثار احمد ارشاد فرماتے ہیں:'

MONTHS = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
}


def unescape(text: str) -> str:
    text = html.unescape(text)
    text = text.replace('<br />', '\n').replace('<br>', '\n')
    text = re.sub(r'<[^>]+>', '', text)
    return re.sub(r'\s+', ' ', text).strip()


def parse_fb_date(raw: str) -> tuple[str, str]:
    raw = raw.strip()
    # Jun 17, 2026 10:18:52 pm
    m = re.match(
        r'([A-Za-z]{3})\s+(\d{1,2}),\s+(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s*(am|pm)',
        raw,
        re.I,
    )
    if not m:
        return raw, datetime.now().isoformat()
    mon, day, year, hour, minute, second, ampm = m.groups()
    h = int(hour) % 12
    if ampm.lower() == 'pm':
        h += 12
    dt = datetime(
        int(year),
        MONTHS[mon.title()],
        int(day),
        h,
        int(minute),
        int(second),
    )
    label = f"{int(day):02d} {mon.title()} {year}"
    return label, dt.isoformat()


def extract_quotes(block: str) -> tuple[str, str] | None:
    if SPEAKER not in block:
        return None
    after = block.split(SPEAKER, 1)[1]
    quotes = re.findall(r'&quot;(.*?)&quot;', after, flags=re.S)
    if len(quotes) < 2:
        quotes = re.findall(r'"([^"]+)"', after, flags=re.S)
    if len(quotes) < 2:
        return None
    urdu = unescape(quotes[0])
    english = unescape(quotes[1])
    if not urdu or not english:
        return None
    return urdu, english


def extract_section_date(section: str) -> tuple[str, str]:
    m = re.search(r'<div class="_a72d">([^<]+)</div>', section)
    if not m:
        return '', datetime.now().isoformat()
    return parse_fb_date(unescape(m.group(1)))


def extract_image_rel_path(section: str) -> str:
    m = re.search(
        r'href="(your_facebook_activity/posts/media/[^"]+\.(?:jpg|jpeg|png|webp))"',
        section,
        re.I,
    )
    return m.group(1) if m else ''


def parse_html(path: Path) -> list[dict]:
    raw = path.read_text(encoding='utf-8', errors='replace')
    sections = re.split(r'<section class="_a6-g"', raw)
    out: list[dict] = []
    seen: set[tuple[str, str]] = set()

    for section in sections:
        if MARKER not in section:
            continue
        # Prefer caption block with both languages.
        caption = ''
        m = re.search(r'<div class="_3-95">(.*?)</div>', section, flags=re.S)
        if m:
            caption = m.group(1)
        quotes = extract_quotes(caption) or extract_quotes(section)
        if not quotes:
            continue
        urdu, english = quotes
        key = (urdu, english)
        if key in seen:
            continue
        seen.add(key)
        date_label, created_at = extract_section_date(section)
        image_rel = extract_image_rel_path(section)
        out.append(
            {
                'dateLabel': date_label,
                'urdu': urdu,
                'english': english,
                'createdAt': created_at,
                'imageRelPath': image_rel,
            }
        )

  # Facebook export lists newest first; app sorts newest first too.
    return out


def main() -> None:
    src = Path(sys.argv[1] if len(sys.argv) > 1 else 'tool/_fb_export/your_posts__check_ins__photos_and_videos_1.html')
    items = parse_html(src)
    dest = Path(sys.argv[2] if len(sys.argv) > 2 else 'tool/_fb_export/irshadat_parsed.json')
    dest.write_text(json.dumps(items, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Parsed {len(items)} unique Irshadat entries -> {dest}')


if __name__ == '__main__':
    main()
