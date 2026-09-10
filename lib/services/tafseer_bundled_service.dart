import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tafseer_models.dart';

/// Tafseer content shipped in app assets (`assets/tafseer/**`).
///
/// Adding a surah is a file drop: a folder under `assets/tafseer/<id>/` plus an
/// entry in `index.json`. Nothing here hits the network.
class TafseerBundledService {
  TafseerBundledService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Parsed surahs, kept so paging between rukus doesn't re-decode the JSON.
  final Map<String, TafseerSurah> _surahCache = {};

  static const _indexPath = 'assets/tafseer/index.json';

  static String _surahPath(String id) => 'assets/tafseer/$id/surah.json';

  static String rukuPath(String id, int number) =>
      'assets/tafseer/$id/rukus/${number.toString().padLeft(2, '0')}.html';

  Future<List<TafseerSurahSummary>> loadIndex() async {
    try {
      final raw = await _bundle.loadString(_indexPath);
      final arr = jsonDecode(raw) as List<dynamic>;
      return arr
          .whereType<Map<String, dynamic>>()
          .map(TafseerSurahSummary.fromJson)
          .where((s) => s.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<TafseerSurah?> loadSurah(String id) async {
    if (id.isEmpty) return null;
    final cached = _surahCache[id];
    if (cached != null) return cached;
    try {
      final raw = await _bundle.loadString(_surahPath(id));
      final surah = TafseerSurah.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      _surahCache[id] = surah;
      return surah;
    } catch (_) {
      return null;
    }
  }

  Future<String?> loadRukuHtml(String id, int number) async {
    if (id.isEmpty || number < 1) return null;
    try {
      return await _bundle.loadString(rukuPath(id, number));
    } catch (_) {
      return null;
    }
  }
}
