import '../models/shajra_entry_model.dart';
import 'shajra_bundled_service.dart';
import 'shajra_scrape_client.dart';

/// Shajra Pak data for the app — reads bundled assets only (no runtime scraping).
class ShajraService {
  ShajraService({
    ShajraBundledService? bundled,
  }) : _bundled = bundled ?? ShajraBundledService();

  final ShajraBundledService _bundled;

  static const int maxEntryNumber = ShajraBundledService.maxEntryNumber;

  Future<List<ShajraEntryModel>> fetchEnglishShajraList() =>
      _bundled.loadEnglishList();

  Future<List<ShajraEntryModel>> fetchUrduShajraList() =>
      _bundled.loadUrduList();

  Future<String> fetchEntryDetail(String detailUrl) async {
    final number = _numberFromDetailUrl(detailUrl);
    if (number != null) {
      final html = await _bundled.loadEnglishDetailHtml(number);
      if (html != null && html.isNotEmpty) return html;
    }
    throw StateError('bundled detail missing');
  }

  Future<String> fetchEntryDetailByNumber(int number) async {
    final html = await _bundled.loadEnglishDetailHtml(number);
    if (html == null || html.isEmpty) {
      throw StateError('bundled detail missing');
    }
    return html;
  }

  Future<String> fetchUrduDetailByNumber(int number) async {
    final html = await _bundled.loadUrduDetailHtml(number);
    if (html == null || html.isEmpty) {
      throw StateError('bundled urdu detail missing');
    }
    return html;
  }

  int? _numberFromDetailUrl(String detailUrl) {
    final uri = Uri.tryParse(detailUrl);
    final seg = uri?.pathSegments ?? const <String>[];
    final numIdx = seg.indexOf('wali-allah-eng');
    if (numIdx >= 0 && numIdx + 1 < seg.length) {
      return int.tryParse(seg[numIdx + 1]);
    }
    return null;
  }

  String extractShortName(String fullTitle) =>
      ShajraScrapeClient.extractShortName(fullTitle);
}
