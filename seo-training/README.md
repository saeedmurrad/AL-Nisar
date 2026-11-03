# SEO training submissions

Understood.

This folder is the Days 1–10 work for the two-week program that runs from Tuesday 27 October 2026 to Monday 9 November 2026. It does not change the AL Nisar app. The site deploy builds Flutter from `lib/` and `web/` only.

Two practice sites, as assigned:

- Zaheer: Daraz Pakistan, https://www.daraz.pk/
- Amna (addressed as Ammara in the note): Kaya Skin Clinic, https://www.kayaskinclinic.com/

Pages were read on Tuesday 3 November 2026 (Asia/Karachi). The Kaya address currently opens the UAE site at `https://www.kayaskinclinic.com/uae/en`. There is no Pakistan path on that host. The audit uses the site the address actually serves.

## What is in here

| Path | What it is |
| --- | --- |
| `tracker.csv` | Dates, deadlines and status for both trainees |
| `check_submission.py` | Checks title length, description length, keyword placement, brand ending, and blog word count |
| `zaheer-daraz/` | Five-page audit, new metas, two blogs, walkthrough |
| `amna-kaya/` | Five-page audit, new metas, two blogs, walkthrough |

Each blog has an outline, a draft, a final, an SEO block, and a short edit note.

## Rules followed

- Copy is original. Policy facts are paraphrased and linked to the Daraz page they came from. No passage is pasted from either site.
- No prices, handset specifications, or other invented figures. Phone details stay on the product page the shopper is reading.
- Clinic posts do not promise a result, a session count, or a pain-free visit. They tell the reader what to ask a clinician.
- No search volumes. The keyword sheets mentioned in the brief were not in this workspace, so each focus keyword is taken from the assigned topic and the intent of the live page.

## Scoring map

| Part | Marks | Where to read it |
| --- | --- | --- |
| Site audit | 10 | `01-site-audit.md` in each trainee folder |
| Meta titles and descriptions | 30 | `02-meta-titles-descriptions.md` and each `seo-block.md` |
| Blog quality | 40 | `final.md` for the four posts |
| Feedback and deadlines | 20 | `tracker.csv`, `seo-check.md`, and `walkthrough.md` |

Printable copies are in `seo-training/pdf/`:

- `SEO-training-submissions.pdf` — both hand-ins
- `Zaheer-Daraz-SEO-submission.pdf`
- `Amna-Kaya-SEO-submission.pdf`

Regenerate them with `python3 seo-training/build_pdf.py`.

Run the checker from the repository root:

```bash
python3 seo-training/check_submission.py
```
