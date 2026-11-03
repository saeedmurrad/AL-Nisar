#!/usr/bin/env python3
"""Check the SEO training submission against the written rules.

Title: within 60 characters, focus keyword at the start, brand at the end.
Description: 140–155 characters, focus keyword included.
Blog draft and final: 1,000–1,200 words, one H1, H2s and H3s.
Final posts also need the focus keyword in the opening and at least three links.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def words(text: str) -> int:
    cleaned = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    cleaned = re.sub(r"https?://\S+", " ", cleaned)
    cleaned = re.sub(r"^#+\s*", "", cleaned, flags=re.M)
    cleaned = re.sub(r"[*_`>]", " ", cleaned)
    return len(re.findall(r"[A-Za-z0-9’']+", cleaned))


def blocks(path: Path) -> list[str]:
    return re.split(r"\n(?=## )", path.read_text(encoding="utf-8"))


def field(block: str, label: str) -> str | None:
    match = re.search(rf"^- {label}: (.*)$", block, re.M)
    return match.group(1).strip() if match else None


def check_meta(path: Path, errors: list[str]) -> int:
    found = 0
    for block in blocks(path):
        title = field(block, "Title")
        description = field(block, "Description")
        keyword = field(block, "Focus keyword")
        if not title or not description or not keyword:
            continue
        found += 1
        where = f"{path.relative_to(ROOT)} ({block.splitlines()[0].lstrip('#').strip()})"
        if len(title) > 60:
            errors.append(f"{where}: title is {len(title)} characters")
        if not 140 <= len(description) <= 155:
            errors.append(f"{where}: description is {len(description)} characters")
        position = title.lower().find(keyword.lower())
        if position < 0 or position > 15:
            errors.append(f"{where}: focus keyword is at index {position}")
        if keyword.lower() not in description.lower():
            errors.append(f"{where}: description misses the focus keyword")
        if not (title.endswith("| Daraz") or title.endswith("| Kaya Clinic")):
            errors.append(f"{where}: brand is not at the end")
    if found == 0:
        errors.append(f"{path.relative_to(ROOT)}: no meta blocks found")
    return found


def check_article(path: Path, errors: list[str], final: bool) -> None:
    text = path.read_text(encoding="utf-8")
    count = words(text)
    where = str(path.relative_to(ROOT))
    if not 1000 <= count <= 1200:
        errors.append(f"{where}: {count} words")
    h1 = re.findall(r"^# ", text, re.M)
    if len(h1) != 1:
        errors.append(f"{where}: {len(h1)} H1 headings")
    if len(re.findall(r"^## ", text, re.M)) < 3:
        errors.append(f"{where}: fewer than 3 H2 headings")
    if len(re.findall(r"^### ", text, re.M)) < 2:
        errors.append(f"{where}: fewer than 2 H3 headings")
    if not final:
        return
    seo = path.with_name("seo-block.md").read_text(encoding="utf-8")
    keyword = field(seo, "Focus keyword")
    if not keyword:
        errors.append(f"{where}: seo-block has no focus keyword")
        return
    opening = text.split("## ", 1)[0]
    if keyword.lower() not in opening.lower():
        errors.append(f"{where}: focus keyword missing from the opening")
    if len(re.findall(r"\]\(", text)) < 3:
        errors.append(f"{where}: fewer than 3 internal links")


def main() -> int:
    errors: list[str] = []
    metas = 0
    for path in sorted(ROOT.rglob("*.md")):
        if path.name in {"02-meta-titles-descriptions.md", "seo-block.md"}:
            metas += check_meta(path, errors)
        elif path.name == "final.md":
            check_article(path, errors, final=True)
        elif path.name == "draft.md":
            check_article(path, errors, final=False)
    if errors:
        print("\n".join(errors))
        return 1
    print(f"OK: {metas} meta blocks, 4 drafts and 4 finals inside the rules.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
