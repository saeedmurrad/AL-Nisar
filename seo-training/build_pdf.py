#!/usr/bin/env python3
"""Build the printable SEO training hand-ins from the Markdown sources."""

from __future__ import annotations

import re
from pathlib import Path

from fpdf import FPDF

ROOT = Path(__file__).resolve().parent
PDF_DIR = ROOT / "pdf"
FONT = Path("/usr/share/fonts/truetype/macos")

INK = (28, 32, 30)
MUTED = (86, 92, 88)
GREEN = (18, 92, 68)
RULE = (214, 218, 214)
PAPER = (255, 255, 255)

TRAINEES = (
    {
        "key": "zaheer",
        "name": "Zaheer Murad",
        "site": "Daraz Pakistan",
        "url": "https://www.daraz.pk/",
        "folder": "zaheer-daraz",
        "file": "Zaheer-Murad-Daraz-SEO-submission.pdf",
        "blogs": (
            (
                "Blog 1. How to Choose the Right Smartphone in Pakistan",
                "blog-1-smartphone",
            ),
            (
                "Blog 2. Online Shopping in Pakistan",
                "blog-2-safe-shopping",
            ),
        ),
    },
)


def words(text: str) -> int:
    cleaned = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    cleaned = re.sub(r"https?://\S+", " ", cleaned)
    cleaned = re.sub(r"^#+\s*", "", cleaned, flags=re.M)
    cleaned = re.sub(r"[*_`>]", " ", cleaned)
    return len(re.findall(r"[A-Za-z0-9’']+", cleaned))


def soften_url(url: str) -> str:
    return url.replace("/", "/\u200b").replace("?", "?\u200b").replace("&", "&\u200b")


def prepare(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        label, url = match.group(1), match.group(2)
        return f"{label} ({soften_url(url)})"

    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", repl, text)
    if text.startswith("Title: ") or text.startswith("Description: "):
        body = text.split(": ", 1)[1]
        text = f"{text} — {len(body)} characters"
    return text


def blocks(text: str) -> list[tuple]:
    lines = text.splitlines()
    parsed: list[tuple] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        if not line.strip():
            index += 1
            continue
        heading = re.match(r"^(#{1,3})\s+(.*)$", line)
        if heading:
            parsed.append(("h", len(heading.group(1)), heading.group(2).strip()))
            index += 1
            continue
        if line.startswith("- "):
            items = []
            while index < len(lines) and lines[index].startswith("- "):
                items.append(lines[index][2:].strip())
                index += 1
            parsed.append(("ul", items))
            continue
        if re.match(r"^\d+\. ", line):
            items = []
            while index < len(lines) and re.match(r"^\d+\. ", lines[index]):
                items.append(re.sub(r"^\d+\.\s+", "", lines[index]).strip())
                index += 1
            parsed.append(("ol", items))
            continue
        parsed.append(("p", line.strip()))
        index += 1
    return parsed


class Handin(FPDF):
    def __init__(self) -> None:
        super().__init__(format="A4", unit="mm")
        self.add_font("Inter", "", str(FONT / "Inter-Regular.ttf"))
        self.add_font("Inter", "B", str(FONT / "Inter-Bold.ttf"))
        self.add_font("Inter", "I", str(FONT / "Inter-Italic.ttf"))
        self.add_font("Inter", "BI", str(FONT / "Inter-BoldItalic.ttf"))
        self.set_auto_page_break(True, margin=16)
        self.set_margins(18, 20, 18)
        self.running_left = ""
        self._quiet = False

    def header(self) -> None:
        if self._quiet:
            self._quiet = False
            return
        self.set_y(8)
        self.set_font("Inter", "", 8.5)
        self.set_text_color(*MUTED)
        self.cell(0, 5, self.running_left, align="L")
        self.set_xy(self.l_margin, 8)
        self.cell(0, 5, "27 October – 9 November 2026", align="R")
        self.set_draw_color(*RULE)
        self.set_line_width(0.2)
        self.line(self.l_margin, 14.5, self.w - self.r_margin, 14.5)
        self.set_y(self.t_margin)

    def footer(self) -> None:
        self.set_y(-12)
        self.set_font("Inter", "", 8.5)
        self.set_text_color(*MUTED)
        self.cell(0, 5, "SEO training submission", align="L")
        self.set_xy(self.l_margin, -12)
        self.cell(0, 5, str(self.page_no()), align="R")

    def ensure(self, height: float) -> None:
        if self.get_y() + height > self.h - self.b_margin:
            self.add_page()

    def gap(self, height: float = 2.2) -> None:
        self.ln(height)

    def write_text(self, text: str, size: float = 11, style: str = "", color=INK, line: float | None = None) -> None:
        self.set_font("Inter", style, size)
        self.set_text_color(*color)
        self.multi_cell(
            0,
            line or size * 0.52,
            prepare(text),
            markdown=True,
            new_x="LMARGIN",
            new_y="NEXT",
        )

    def item(self, mark: str, text: str) -> None:
        self.ensure(12)
        self.set_font("Inter", "", 11)
        self.set_text_color(*INK)
        top = self.get_y()
        self.set_x(self.l_margin)
        self.cell(7, 5.6, mark)
        self.set_xy(self.l_margin + 7, top)
        self.multi_cell(
            self.epw - 7,
            5.6,
            prepare(text),
            markdown=True,
            new_x="LMARGIN",
            new_y="NEXT",
        )
        self.ln(0.8)

    def render_blocks(self, text: str, word_note: str | None = None) -> None:
        first_heading = True
        for kind, *rest in blocks(text):
            if kind == "h":
                level, title = rest
                if level == 1:
                    self.ensure(32)
                    if self.get_y() > self.t_margin + 1:
                        self.gap(3)
                    self.set_font("Inter", "B", 16)
                    self.set_text_color(*INK)
                    self.multi_cell(0, 7.2, title, new_x="LMARGIN", new_y="NEXT")
                    self.set_draw_color(*GREEN)
                    self.set_line_width(0.4)
                    y = self.get_y() + 1.2
                    self.line(self.l_margin, y, self.l_margin + 28, y)
                    self.ln(4)
                    if word_note and first_heading:
                        self.write_text(word_note, size=9.5, style="I", color=MUTED, line=5)
                        self.gap(1.5)
                    first_heading = False
                elif level == 2:
                    self.ensure(34)
                    self.gap(2.4)
                    self.write_text(title, size=13, style="B", line=6.2)
                    self.gap(1)
                else:
                    self.ensure(26)
                    self.gap(1.6)
                    self.write_text(title, size=11.5, style="B", line=5.6)
                    self.gap(0.6)
            elif kind == "p":
                paragraph = rest[0]
                if paragraph.startswith("Status:"):
                    self.write_text(paragraph, size=10, style="I", color=MUTED, line=5)
                else:
                    self.write_text(paragraph)
                self.gap(1.6)
            elif kind == "ul":
                for entry in rest[0]:
                    self.item("•", entry)
                self.gap(1)
            elif kind == "ol":
                for number, entry in enumerate(rest[0], start=1):
                    self.item(f"{number}.", entry)
                self.gap(1)

    def cover(self, kicker: str, title: str, lines: list[str], contents: list[str]) -> None:
        self._quiet = True
        self.add_page()
        self.set_y(28)
        self.set_font("Inter", "B", 11)
        self.set_text_color(*GREEN)
        self.cell(0, 6, kicker, new_x="LMARGIN", new_y="NEXT")
        self.ln(3)
        self.set_font("Inter", "B", 26)
        self.set_text_color(*INK)
        self.multi_cell(0, 11, title, new_x="LMARGIN", new_y="NEXT")
        self.ln(4)
        self.set_draw_color(*GREEN)
        self.set_line_width(0.6)
        self.line(self.l_margin, self.get_y(), self.l_margin + 36, self.get_y())
        self.ln(8)
        for line in lines:
            self.set_font("Inter", "", 12)
            self.set_text_color(*INK)
            self.multi_cell(0, 6.4, line, new_x="LMARGIN", new_y="NEXT")
            self.ln(1.2)
        self.ln(8)
        self.set_font("Inter", "B", 11)
        self.set_text_color(*GREEN)
        self.cell(0, 6, "IN THIS FILE", new_x="LMARGIN", new_y="NEXT")
        self.ln(2)
        for entry in contents:
            self.set_font("Inter", "", 12)
            self.set_text_color(*INK)
            self.cell(0, 7, entry, new_x="LMARGIN", new_y="NEXT")

    def part(
        self,
        bookmark: str,
        path: Path,
        running: str,
        word_note: str | None = None,
        new_page: bool = False,
    ) -> None:
        self.running_left = running
        if new_page:
            self.add_page()
        self.start_section(bookmark)
        self.render_blocks(path.read_text(encoding="utf-8"), word_note=word_note)


def blog_parts(folder: Path) -> list[tuple[str, Path, str | None]]:
    labels = (
        ("Outline", "outline.md", None),
        ("SEO block", "seo-block.md", None),
        ("Draft", "draft.md", "draft"),
        ("Final", "final.md", "final"),
        ("Edit check", "seo-check.md", None),
    )
    parts = []
    for label, name, kind in labels:
        path = folder / name
        note = None
        if kind:
            note = f"{words(path.read_text(encoding='utf-8')):,} words. The assigned range is 1,000–1,200."
        parts.append((label, path, note))
    return parts


def add_trainee(pdf: Handin, trainee: dict, divider: bool) -> None:
    folder = ROOT / trainee["folder"]
    if divider:
        pdf.cover(
            trainee["name"].upper(),
            trainee["site"],
            [
                trainee["url"],
                "Pages read on Tuesday 3 November 2026 (Asia/Karachi).",
                "Titles are within 60 characters. Descriptions are 140–155 characters.",
                "Drafts and finals are 1,000–1,200 words.",
            ],
            [
                "Site audit",
                "Meta titles and descriptions",
                trainee["blogs"][0][0],
                trainee["blogs"][1][0],
                "Five-minute walkthrough",
            ],
        )
    name = trainee["name"]
    pdf.part(
        f"{name} — site audit",
        folder / "01-site-audit.md",
        f"{name}  ·  Site audit",
        new_page=True,
    )
    pdf.part(
        f"{name} — meta titles and descriptions",
        folder / "02-meta-titles-descriptions.md",
        f"{name}  ·  Meta titles",
        new_page=True,
    )
    for number, (title, slug) in enumerate(trainee["blogs"], start=1):
        blog = folder / slug
        first = True
        for label, path, note in blog_parts(blog):
            pdf.part(
                f"{name} — {title} — {label}",
                path,
                f"{name}  ·  Blog {number}  ·  {label}",
                word_note=note,
                new_page=first,
            )
            first = False
    pdf.part(
        f"{name} — walkthrough",
        folder / "walkthrough.md",
        f"{name}  ·  Walkthrough",
        new_page=True,
    )


def build_one(trainee: dict) -> Path:
    pdf = Handin()
    pdf.set_title(f"SEO training submission — {trainee['name']}")
    pdf.set_author(trainee["name"])
    pdf.cover(
        "SEO TRAINING  ·  27 OCTOBER – 9 NOVEMBER 2026",
        f"{trainee['name']}\n{trainee['site']}",
        [
            trainee["url"],
            "Hand-in for days 1 to 10.",
            "Pages were read on Tuesday 3 November 2026 (Asia/Karachi).",
            "No prices or handset specifications were added.",
        ],
        [
            "1    Site audit of five live pages",
            "2    New meta titles and descriptions",
            f"3    {trainee['blogs'][0][0]}",
            f"4    {trainee['blogs'][1][0]}",
            "5    Five-minute walkthrough",
        ],
    )
    add_trainee(pdf, trainee, divider=False)
    PDF_DIR.mkdir(exist_ok=True)
    destination = PDF_DIR / trainee["file"]
    pdf.output(destination)
    return destination


def main() -> None:
    written = [build_one(trainee) for trainee in TRAINEES]
    for path in written:
        print(f"{path.relative_to(ROOT)}  {path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
