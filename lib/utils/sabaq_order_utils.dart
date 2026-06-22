import '../models/sabaq_pdf_model.dart';

/// Parses lesson order from titles like "Sabaq 05 — …" or "5th Sabaq".
int? parseSabaqOrderNumber(String titleEn, {String? titleUr}) {
  final en = titleEn.trim();
  if (en.isNotEmpty) {
    final prefixed = RegExp(
      r'sabaq\s*#?\s*0*(\d+)',
      caseSensitive: false,
    ).firstMatch(en);
    if (prefixed != null) {
      return int.tryParse(prefixed.group(1)!);
    }
    final ordinal = RegExp(
      r'(\d+)(?:st|nd|rd|th)?\s+sabaq',
      caseSensitive: false,
    ).firstMatch(en);
    if (ordinal != null) {
      return int.tryParse(ordinal.group(1)!);
    }
  }

  final ur = (titleUr ?? '').trim();
  if (ur.isNotEmpty) {
    const urduOrdinals = {
      'پہلا': 1,
      'دوسرا': 2,
      'تیسرا': 3,
      'چوتھا': 4,
      'پانچواں': 5,
      'چھٹا': 6,
      'ساتواں': 7,
      'آٹھواں': 8,
      'نواں': 9,
      'دسواں': 10,
    };
    for (final entry in urduOrdinals.entries) {
      if (ur.contains(entry.key)) return entry.value;
    }
  }

  return null;
}

int sabaqOrderFor(SabaqPdfModel model) =>
    model.orderNumber ?? parseSabaqOrderNumber(model.titleEn, titleUr: model.titleUr) ?? 1 << 30;

/// Keeps the newest upload when the same lesson number (or title) appears twice.
List<SabaqPdfModel> dedupeSabaqList(List<SabaqPdfModel> list) {
  final byOrder = <int, SabaqPdfModel>{};
  final byTitle = <String, SabaqPdfModel>{};

  for (final item in list) {
    final order = item.orderNumber ?? parseSabaqOrderNumber(item.titleEn, titleUr: item.titleUr);
    if (order != null) {
      final existing = byOrder[order];
      if (existing == null || item.uploadedAt.isAfter(existing.uploadedAt)) {
        byOrder[order] = item;
      }
      continue;
    }

    final key = item.titleEn.trim().toLowerCase();
    if (key.isEmpty) continue;
    final existing = byTitle[key];
    if (existing == null || item.uploadedAt.isAfter(existing.uploadedAt)) {
      byTitle[key] = item;
    }
  }

  final out = [...byOrder.values, ...byTitle.values];
  out.sort((a, b) {
    final ao = sabaqOrderFor(a);
    final bo = sabaqOrderFor(b);
    if (ao != bo) return ao.compareTo(bo);
    final at = a.uploadedAt.compareTo(b.uploadedAt);
    if (at != 0) return at;
    return a.id.compareTo(b.id);
  });
  return out;
}
