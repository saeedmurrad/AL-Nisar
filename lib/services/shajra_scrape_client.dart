import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/shajra_entry_model.dart';

/// HTTP scraper for yarasoolallah.net — used only by [tool/fetch_shajra_bundle.dart].
class ShajraScrapeClient {
  ShajraScrapeClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'https://www.yarasoolallah.net';
  static const String englishListUrl =
      'https://www.yarasoolallah.net/shajra-mubarik-english/';
  static const String urduListUrl =
      'https://www.yarasoolallah.net/shajra-mubarik-urdu/';

  static const int maxEntryNumber = 40;

  Future<List<ShajraEntryModel>> fetchEnglishShajraList() async {
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
        if (n == null || n > maxEntryNumber) continue;

        final a = tds[1].querySelector('a[href]');
        if (a == null) continue;
        final href = (a.attributes['href'] ?? '').trim();
        if (href.isEmpty) continue;

        final fullTitle = a.text.trim();
        if (fullTitle.isEmpty) continue;

        final String detailUrl;
        if (href.contains('drive.google.com')) {
          detailUrl = '';
        } else {
          if (!href.contains('wali-allah-eng')) continue;
          final absolute = _absoluteUrl(href);
          if (!absolute.contains('yarasoolallah')) continue;
          detailUrl = absolute;
        }

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

    return _dedupeSorted(out);
  }

  Future<List<ShajraEntryModel>> fetchUrduShajraList() async {
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

        if (number > maxEntryNumber) continue;

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

    return _dedupeSorted(out);
  }

  Future<String> fetchEntryDetailHtml(String detailUrl) async {
    if (detailUrl.isEmpty) {
      throw StateError('empty detail url');
    }
    final body = await _httpGet(detailUrl);
    final doc = html_parser.parse(body);
    final html = _buildArticleHtml(doc);
    if (html == null || html.isEmpty) {
      throw StateError('no article content');
    }
    return html;
  }

  List<ShajraEntryModel> _dedupeSorted(List<ShajraEntryModel> out) {
    out.sort((a, b) => a.number.compareTo(b.number));
    final deduped = <int, ShajraEntryModel>{};
    for (final e in out) {
      deduped[e.number] = e;
    }
    return deduped.values.toList()..sort((a, b) => a.number.compareTo(b.number));
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

  static String extractShortName(String fullTitle) {
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

  /// Compact label for Urdu Shajra list rows (text after the last حضرت).
  static String extractUrduShortName(String fullTitle) {
    var t = fullTitle.trim();
    if (t.isEmpty) return t;

    const hazrat = 'حضرت';
    final idx = t.lastIndexOf(hazrat);
    if (idx >= 0) {
      t = t.substring(idx + hazrat.length).trim();
    }

    t = t
        .replaceAll(RegExp(r'\s*رضی\s+اللہ\s+تعالیٰ\s+عنہ\s*$'), '')
        .replaceAll(RegExp(r'\s*دامت\s+برکاتہم\s+العالیہ\s*$'), '')
        .trim();

    if (t.isNotEmpty) return t;

    final parts = fullTitle.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 3) {
      final start = parts.length - 4 >= 0 ? parts.length - 4 : 0;
      return parts.sublist(start).join(' ');
    }
    return fullTitle.trim();
  }

  /// Entries 1–38 use Hazrat Khawaja … Raziallah Taala Anhu in list rows.
  static const int listHonorificEndEntry = 38;

  static String listLabelEnglish(String fullTitle, int number) {
    if (number == 1) {
      return 'Hazrat Muhammad Rasool Allah SAW';
    }
    if (number == 39 || number == 40) {
      final base = extractShortName(fullTitle);
      if (base.toLowerCase().startsWith('hazrat')) return base;
      return 'Hazrat $base';
    }
    if (number > listHonorificEndEntry) {
      return extractShortName(fullTitle);
    }
    final core = _stripEnglishListCore(extractShortName(fullTitle));
    if (core.isEmpty) return fullTitle.trim();
    return 'Hazrat Khawaja $core Raziallah Taala Anhu';
  }

  static String listLabelUrdu(String fullTitle, int number) {
    if (number == 1) {
      return 'حضرت محمد رسول اللہ صلی اللہ علیہ وآلہ وسلم';
    }
    if (number == 39 || number == 40) {
      final base = extractUrduShortName(fullTitle);
      if (base.startsWith('حضرت')) return base;
      return 'حضرت $base';
    }
    if (number > listHonorificEndEntry) {
      return extractUrduShortName(fullTitle);
    }
    final core = _stripUrduListCore(extractUrduShortName(fullTitle));
    if (core.isEmpty) return fullTitle.trim();
    return 'حضرت خواجہ $core رضی اللہ تعالیٰ عنہ';
  }

  static String _stripEnglishListCore(String core) {
    var t = core.trim();
    while (true) {
      final before = t;
      t = t.replaceAll(
        RegExp(
          r'^(hazrat|khwaja|khawaja|khwaja-gi|sheikh|imam)\s+',
          caseSensitive: false,
        ),
        '',
      );
      t = t.replaceAll(RegExp(r'\s+(ra|r\.a\.)\s*$', caseSensitive: false), '');
      t = t.replaceAll(
        RegExp(r'\s+razi\s*allah\s*anhu\s*$', caseSensitive: false),
        '',
      );
      t = t.replaceAll(
        RegExp(r'\s+raziallah\s+taala\s+anhu\s*$', caseSensitive: false),
        '',
      );
      if (t == before) break;
    }
    return t.trim();
  }

  static String _stripUrduListCore(String core) {
    var t = core.trim();
    while (true) {
      final before = t;
      t = t.replaceAll(RegExp(r'^(حضرت|خواجہ|خواجگی|شیخ|امام)\s+'), '');
      t = t.replaceAll(RegExp(r'\s*رضی\s+اللہ\s+تعالیٰ\s+عنہ\s*$'), '');
      if (t == before) break;
    }
    return t.trim();
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
    final res = await _client
        .get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (compatible; ALNisarApp/1.0; +https://example.invalid)',
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

  void close() => _client.close();
}
