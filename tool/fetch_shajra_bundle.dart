// ignore_for_file: avoid_print
//
// One-time dev script: downloads Shajra Pak entries 1–40 and writes bundled assets.
// Run from project root: dart run tool/fetch_shajra_bundle.dart

import 'dart:convert';
import 'dart:io';

import 'package:spiritual_learning_app/models/shajra_entry_model.dart';
import 'package:spiritual_learning_app/services/shajra_scrape_client.dart';

Future<void> main() async {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run from the Flutter project root.');
    exit(1);
  }

  final scrape = ShajraScrapeClient();
  final assetsRoot = Directory('${root.path}/assets/shajra');
  final englishDetails = Directory('${assetsRoot.path}/english/details');

  try {
    print('Fetching English list…');
    final english = await scrape.fetchEnglishShajraList();
    print('  ${english.length} entries');

    print('Fetching Urdu list…');
    final urdu = await scrape.fetchUrduShajraList();
    print('  ${urdu.length} entries');

    englishDetails.createSync(recursive: true);

    print('Fetching English detail HTML…');
    for (final e in english) {
      stdout.write('  #${e.number}… ');
      try {
        final String html;
        if (e.detailUrl.isEmpty) {
          html = _placeholderDetailHtml(e.fullTitle);
          print('placeholder');
        } else {
          html = await scrape.fetchEntryDetailHtml(e.detailUrl);
          print('ok');
        }
        final path =
            '${englishDetails.path}/${e.number.toString().padLeft(2, '0')}.html';
        await File(path).writeAsString(html);
      } catch (err) {
        print('FAILED: $err');
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    await _writeList(
      '${assetsRoot.path}/english/list.json',
      english,
    );
    await _writeList(
      '${assetsRoot.path}/urdu/list.json',
      urdu,
    );

    print('Done. Assets written under assets/shajra/');
  } finally {
    scrape.close();
  }
}

Future<void> _writeList(String path, List<ShajraEntryModel> list) async {
  final file = File(path);
  file.parent.createSync(recursive: true);
  final json = jsonEncode(list.map((e) => e.toJson()).toList());
  await file.writeAsString('${const JsonEncoder.withIndent('  ').convert(jsonDecode(json))}\n');
}

String _placeholderDetailHtml(String fullTitle) {
  final title = fullTitle
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  return '<h2>$title</h2>'
      '<p>Detailed biography for this entry is available as a PDF on the '
      'original Shajra Pak website only.</p>';
}
