import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shajra_entry_model.dart';

class ShajraService {
  static const String baseUrl = 'https://www.yarasoolallah.net';
  static const String englishListUrl =
      'https://www.yarasoolallah.net/shajra-mubarik-english/';
  static const String urduListUrl =
      'https://www.yarasoolallah.net/shajra-mubarik-urdu/';

  static const String _prefsListKey = 'shajra_english_list';
  static const String _prefsListTsKey = 'shajra_english_list_ts';
  static const Duration _listTtl = Duration(hours: 24);

  static const Duration _detailTtl = Duration(hours: 48);

  static String _detailCacheKey(int number) => 'shajra_detail_$number';

  static String _detailTsKey(int number) => 'shajra_detail_${number}_ts';

  Future<List<ShajraEntryModel>> fetchEnglishShajraList() async {
    final prefs = await SharedPreferences.getInstance();
    final tsMs = prefs.getInt(_prefsListTsKey);
    if (tsMs != null) {
      final age = DateTime.now().millisecondsSinceEpoch - tsMs;
      if (age < _listTtl.inMilliseconds) {
        final raw = prefs.getString(_prefsListKey);
        if (raw != null && raw.isNotEmpty) {
          try {
            final list = jsonDecode(raw) as List<dynamic>;
            return list
                .map((e) => ShajraEntryModel.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (_) {}
        }
      }
    }

    final body = await _httpGet(englishListUrl);
    final doc = html_parser.parse(body);
    final out = <ShajraEntryModel>[];

    for (final table in doc.getElementsByTagName('table')) {
      for (final tr in table.getElementsByTagName('tr')) {
        final tds = tr.getElementsByTagName('td');
        if (tds.length < 2) continue;
        final numText = tds[0].text.trim();
        final numMatch = RegExp(r'(\d+)').firstMatch(numText);
        if (numMatch == null) continue;
        final n = int.tryParse(numMatch.group(1)!);
        if (n == null) continue;

        final a = tds[1].querySelector('a[href]');
        if (a == null) continue;
        final href = (a.attributes['href'] ?? '').trim();
        if (href.isEmpty) continue;
        if (!href.contains('wali-allah-eng')) continue;
        if (href.contains('drive.google.com')) continue;

        final detailUrl = _absoluteUrl(href);
        if (!detailUrl.contains('yarasoolallah')) continue;

        final fullTitle = a.text.trim();
        if (fullTitle.isEmpty) continue;

        out.add(
          ShajraEntryModel(
            number: n,
            fullTitle: fullTitle,
            shortName: extractShortName(fullTitle),
            detailUrl: detailUrl,
            language: ShajraEntryModel.english,
          ),
        );
      }
    }

    out.sort((a, b) => a.number.compareTo(b.number));
    final deduped = <int, ShajraEntryModel>{};
    for (final e in out) {
      deduped[e.number] = e;
    }
    final list = deduped.values.toList()..sort((a, b) => a.number.compareTo(b.number));

    if (list.isNotEmpty) {
      await prefs.setString(
        _prefsListKey,
        jsonEncode(list.map((e) => e.toJson()).toList()),
      );
      await prefs.setInt(_prefsListTsKey, DateTime.now().millisecondsSinceEpoch);
    }

    return list;
  }

  /// Urdu list: table rows with number + name only ([detailUrl] always empty).
  /// Cached under [shajra_urdu_list] as JSON with 24h expiry.
  Future<List<ShajraEntryModel>> fetchUrduShajraList() async {
    const cacheKey = 'shajra_urdu_list';
    final prefs = await SharedPreferences.getInstance();
    final cachedRaw = prefs.getString(cacheKey);
    if (cachedRaw != null && cachedRaw.isNotEmpty) {
      try {
        final wrap = jsonDecode(cachedRaw) as Map<String, dynamic>;
        final saved = wrap['savedAtMs'];
        if (saved is int) {
          final age = DateTime.now().millisecondsSinceEpoch - saved;
          if (age < _listTtl.inMilliseconds) {
            final arr = wrap['entries'];
            if (arr is List<dynamic>) {
              return arr
                  .map((e) => ShajraEntryModel.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          }
        }
      } catch (_) {}
    }

    final body = await _httpGet(urduListUrl);
    final doc = html_parser.parse(body);
    final out = <ShajraEntryModel>[];

    for (final table in doc.getElementsByTagName('table')) {
      for (final tr in table.getElementsByTagName('tr')) {
        final tds = tr.getElementsByTagName('td');
        if (tds.length < 2) continue;

        final n0 = _plainIndexFromCellText(tds[0].text);
        final n1 = _plainIndexFromCellText(tds[1].text);

        late final int number;
        late final Element nameTd;
        if (n0 != null && n1 == null) {
          number = n0;
          nameTd = tds[1];
        } else if (n1 != null && n0 == null) {
          number = n1;
          nameTd = tds[0];
        } else {
          continue;
        }

        final name = _urduNameFromTableCell(nameTd);
        if (name.isEmpty) continue;

        out.add(
          ShajraEntryModel(
            number: number,
            fullTitle: name,
            shortName: name,
            detailUrl: '',
            language: ShajraEntryModel.urdu,
          ),
        );
      }
    }

    out.sort((a, b) => a.number.compareTo(b.number));
    final deduped = <int, ShajraEntryModel>{};
    for (final e in out) {
      deduped[e.number] = e;
    }
    final list = deduped.values.toList()..sort((a, b) => a.number.compareTo(b.number));

    if (list.isNotEmpty) {
      await prefs.setString(
        cacheKey,
        jsonEncode({
          'savedAtMs': DateTime.now().millisecondsSinceEpoch,
          'entries': list.map((e) => e.toJson()).toList(),
        }),
      );
    }

    return list;
  }

  int? _plainIndexFromCellText(String raw) {
    final t = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final m = RegExp(r'^(\d+)\.?\s*$').firstMatch(t);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  String _urduNameFromTableCell(Element td) {
    final a = td.querySelector('a');
    final text = (a?.text ?? td.text).trim();
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<String> fetchEntryDetail(String detailUrl) async {
    if (detailUrl.isEmpty) {
      throw StateError('empty detail url');
    }

    final prefs = await SharedPreferences.getInstance();
    final uri = Uri.tryParse(detailUrl);
    final seg = uri?.pathSegments ?? const <String>[];
    final numIdx = seg.indexOf('wali-allah-eng');
    int? number;
    if (numIdx >= 0 && numIdx + 1 < seg.length) {
      number = int.tryParse(seg[numIdx + 1]);
    }

    if (number != null) {
      final tsMs = prefs.getInt(_detailTsKey(number));
      if (tsMs != null) {
        final age = DateTime.now().millisecondsSinceEpoch - tsMs;
        if (age < _detailTtl.inMilliseconds) {
          final cached = prefs.getString(_detailCacheKey(number));
          if (cached != null && cached.isNotEmpty) return cached;
        }
      }
    }

    final body = await _httpGet(detailUrl);
    final doc = html_parser.parse(body);
    final html = _buildArticleHtml(doc);
    if (html == null || html.isEmpty) {
      throw StateError('no article content');
    }

    if (number != null) {
      await prefs.setString(_detailCacheKey(number), html);
      await prefs.setInt(
        _detailTsKey(number),
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    return html;
  }

  String extractShortName(String fullTitle) {
    final t = fullTitle.trim();
    if (t.isEmpty) return t;

    final lower = t.toLowerCase();
    const key = 'hazrat';
    var idx = lower.lastIndexOf(key);
    if (idx >= 0) {
      var after = t.substring(idx + key.length).trim();
      if (after.startsWith('.')) {
        after = after.substring(1).trim();
      }
      if (after.isNotEmpty) return after;
    }

    final parts = t.split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      return parts
          .sublist(parts.length - 4 >= 0 ? parts.length - 4 : 0)
          .join(' ');
    }
    return t;
  }

  String _absoluteUrl(String href) {
    if (href.startsWith('http://') || href.startsWith('https://')) {
      return href;
    }
    if (href.startsWith('//')) {
      return 'https:$href';
    }
    if (href.startsWith('/')) {
      return '$baseUrl$href';
    }
    return '$baseUrl/$href';
  }

  Future<String> _httpGet(String url) async {
    final res = await http
        .get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (compatible; AlNisarApp/1.0; +https://example.invalid)',
          },
        )
        .timeout(const Duration(seconds: 45));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw http.ClientException('HTTP ${res.statusCode}', Uri.parse(url));
    }
    return res.body;
  }

  String? _buildArticleHtml(Document doc) {
    final candidates = <Element?>[
      doc.querySelector('.entry-content'),
      doc.querySelector('article'),
      doc.querySelector('main'),
      doc.querySelector('#content'),
      doc.querySelector('.post-content'),
      doc.body,
    ];

    for (final root in candidates) {
      if (root == null) continue;

      final h2 = root.querySelector('h2');
      final h1 = root.querySelector('h1');
      final titleEl = h2 ?? h1;
      final paras = root.querySelectorAll('p');
      if (paras.isEmpty && titleEl == null) continue;

      final buf = StringBuffer();
      if (titleEl != null) {
        final titleText = titleEl.text.trim();
        if (titleText.isNotEmpty) {
          buf.write('<h2>${_escapeHtml(titleText)}</h2>');
        }
      }

      for (final p in paras) {
        final clone = p.clone(true);
        _stripMedia(clone);
        final outer = clone.outerHtml;
        if (outer.trim().isNotEmpty) {
          buf.write(outer);
        }
      }

      final s = buf.toString().trim();
      if (s.isNotEmpty) return s;
    }

    return null;
  }

  void _stripMedia(Element el) {
    el.getElementsByTagName('img').toList().forEach((e) => e.remove());
    el.getElementsByTagName('iframe').toList().forEach((e) => e.remove());
    el.getElementsByTagName('video').toList().forEach((e) => e.remove());
  }

  String _escapeHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
