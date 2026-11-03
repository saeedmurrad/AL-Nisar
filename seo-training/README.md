# SEO training submission

Understood.

This folder is Zaheer Murad’s Days 1–10 work for the program that runs from Tuesday 27 October 2026 to Monday 9 November 2026. His practice site is Daraz Pakistan, https://www.daraz.pk/. It does not change the AL Nisar app. The site deploy builds Flutter from `lib/` and `web/` only.

Pages were read on Tuesday 3 November 2026 (Asia/Karachi).

## What is in here

| Path | What it is |
| --- | --- |
| `tracker.csv` | Dates, deadlines and status |
| `check_submission.py` | Checks title length, description length, keyword placement, brand ending, and blog word count |
| `zaheer-daraz/` | Five-page audit, new metas, two blogs, walkthrough |
| `pdf/Zaheer-Murad-Daraz-SEO-submission.pdf` | The printable hand-in |

Each blog has an outline, a draft, a final, an SEO block, and a short edit note.

## Rules followed

- Copy is original. Policy facts are paraphrased and linked to the Daraz page they came from.
- No prices, handset specifications, or other invented figures. Phone details stay on the product page the shopper is reading.
- No search volumes. The keyword sheet was not in this workspace, so each focus keyword is taken from the assigned topic and the intent of the live page.

## Scoring map

| Part | Marks | Where to read it |
| --- | --- | --- |
| Site audit | 10 | `zaheer-daraz/01-site-audit.md` |
| Meta titles and descriptions | 30 | `zaheer-daraz/02-meta-titles-descriptions.md` and each `seo-block.md` |
| Blog quality | 40 | `final.md` for the two posts |
| Feedback and deadlines | 20 | `tracker.csv`, `seo-check.md`, and `walkthrough.md` |

Regenerate the PDF with `python3 seo-training/build_pdf.py`.

Run the checker from the repository root:

```bash
python3 seo-training/check_submission.py
```
