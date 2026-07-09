import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/shajra_entry_model.dart';
import 'shajra_scrape_client.dart';

/// Offline Shajra Pak data shipped in app assets (entries 1–40).
class ShajraBundledService {
  ShajraBundledService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const int maxEntryNumber = 40;

  /// Entry numbers with bundled Urdu biography HTML (offline).
  static const Set<int> bundledUrduDetailNumbers = {40};

  static bool hasBundledUrduDetail(int number) =>
      bundledUrduDetailNumbers.contains(number);

  static const _englishListPath = 'assets/shajra/english/list.json';
  static const _urduListPath = 'assets/shajra/urdu/list.json';
  static String _englishDetailPath(int number) =>
      'assets/shajra/english/details/${number.toString().padLeft(2, '0')}.html';
  static String _urduDetailPath(int number) =>
      'assets/shajra/urdu/details/${number.toString().padLeft(2, '0')}.html';

  Future<List<ShajraEntryModel>> loadEnglishList() =>
      _loadList(_englishListPath);

  Future<List<ShajraEntryModel>> loadUrduList() => _loadList(_urduListPath);

  Future<List<ShajraEntryModel>> _loadList(String assetPath) async {
    try {
      final raw = await _bundle.loadString(assetPath);
      final arr = jsonDecode(raw) as List<dynamic>;
      final list =
          arr
              .map(
                (e) => _withResolvedShortName(
                  ShajraEntryModel.fromJson(e as Map<String, dynamic>),
                ),
              )
              .where((e) => e.number > 0 && e.number <= maxEntryNumber)
              .toList()
            ..sort((a, b) => a.number.compareTo(b.number));
      if (list.isNotEmpty) return list;
    } catch (_) {
      // fall through
    }
    return [];
  }

  static ShajraEntryModel _withResolvedShortName(ShajraEntryModel e) {
    final full = e.fullTitle.trim();
    final resolved = e.language == ShajraEntryModel.urdu
        ? ShajraScrapeClient.listLabelUrdu(full, e.number)
        : ShajraScrapeClient.listLabelEnglish(full, e.number);
    if (resolved == e.shortName) return e;
    return ShajraEntryModel(
      number: e.number,
      fullTitle: e.fullTitle,
      shortName: resolved,
      detailUrl: e.detailUrl,
      language: e.language,
    );
  }

  Future<String?> loadEnglishDetailHtml(int number) async {
    if (number < 1 || number > maxEntryNumber) return null;
    try {
      return await _bundle.loadString(_englishDetailPath(number));
    } catch (_) {
      return null;
    }
  }

  Future<String?> loadUrduDetailHtml(int number) async {
    if (number < 1 || number > maxEntryNumber) return null;
    try {
      return await _bundle.loadString(_urduDetailPath(number));
    } catch (_) {
      return null;
    }
  }
}
