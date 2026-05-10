import 'package:shared_preferences/shared_preferences.dart';

class ReadingProgressService {
  static const _prefix = 'last_page_';

  Future<int?> getLastPage(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$bookId');
  }

  Future<void> setLastPage(String bookId, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$bookId', page);
  }

  Future<void> clearLastPage(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$bookId');
  }
}
