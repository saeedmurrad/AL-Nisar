// Precomputes the Tafseer full-text search index.
//
// Run from the project root, before `flutter build`:
//
//     dart run tool/build_tafseer_search_index.dart
//
// It walks `assets/tafseer/**` exactly as the app would and writes
// `assets/tafseer/search-index.json`. Without it the app still searches —
// it just has to read all 114 surahs and 558 ruku bodies to do so, which is
// the whole 18MB of bundled content before the first query can answer.
//
// The generated file is committed, and `test/tafseer_search_index_test.dart`
// fails if it has drifted from the content, so adding a surah cannot silently
// leave it stale.

import 'dart:convert';
import 'dart:io';

import 'package:spiritual_learning_app/models/tafseer_models.dart';
import 'package:spiritual_learning_app/utils/tafseer_passages.dart';
import 'package:spiritual_learning_app/utils/tafseer_search_index.dart';

const tafseerAssetsDir = 'assets/tafseer';

/// Path of the generated index, relative to the project root.
String tafseerSearchIndexPath([String assetsDir = tafseerAssetsDir]) =>
    '$assetsDir/search-index.json';

/// Builds the index from the content on disk and returns it encoded.
Future<String> buildTafseerSearchIndexJson([
  String assetsDir = tafseerAssetsDir,
]) async {
  final indexFile = File('$assetsDir/index.json');
  final summaries =
      (jsonDecode(await indexFile.readAsString()) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(TafseerSurahSummary.fromJson)
          .where((s) => s.id.isNotEmpty);

  final passages = <TafseerPassage>[];
  for (final summary in summaries) {
    final surahFile = File('$assetsDir/${summary.id}/surah.json');
    if (!surahFile.existsSync()) continue;
    final surah = TafseerSurah.fromJson(
      jsonDecode(await surahFile.readAsString()) as Map<String, dynamic>,
    );

    for (final ruku in surah.rukus) {
      final padded = ruku.number.toString().padLeft(2, '0');
      final body = File('$assetsDir/${surah.id}/rukus/$padded.html');
      if (!body.existsSync()) continue;
      passages.addAll(
        tafseerRukuPassages(
          surah: surah,
          ruku: ruku,
          bodyHtml: await body.readAsString(),
        ),
      );
    }
  }

  return encodeTafseerSearchIndex(passages);
}

Future<void> main(List<String> args) async {
  final assetsDir = args.isNotEmpty ? args.first : tafseerAssetsDir;
  if (!Directory(assetsDir).existsSync()) {
    stderr.writeln('No such directory: $assetsDir (run from the repo root)');
    exitCode = 1;
    return;
  }

  final json = await buildTafseerSearchIndexJson(assetsDir);
  final out = File(tafseerSearchIndexPath(assetsDir));
  final changed = !out.existsSync() || await out.readAsString() != json;
  if (changed) await out.writeAsString(json);

  final passages = decodeTafseerSearchIndex(json)!;
  final mb = (json.length / (1024 * 1024)).toStringAsFixed(1);
  stdout.writeln(
    '${out.path}: ${passages.length} passages, $mb MB'
    '${changed ? '' : ' (already current)'}',
  );
}
