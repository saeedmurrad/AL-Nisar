import '../models/tafseer_models.dart';
import 'arabic_search_text.dart';

/// Surahs a reader typing [query] is probably looking for, in surah order.
///
/// The Tafseer search box answers two different questions with one field —
/// "where does it say this" and "take me to this surah" — so the surahs a
/// query names are offered above the passages that quote it.
///
/// A query matches on the Urdu name, on the surah number in either numeral
/// set, or on the id, which is the Latin spelling: nobody should have to
/// produce `یٰسٓ` on a phone keyboard to reach surah 36 when `yasin` is right
/// there. A single character is treated as the start of typing rather than a
/// filter, since `ا` or `a` would otherwise name half the Quran.
List<TafseerSurahSummary> tafseerSurahsMatching(
  List<TafseerSurahSummary> surahs,
  String query,
) {
  final needle = foldQuery(query);
  if (needle.isEmpty) return const [];

  return surahs.where((s) {
    // An exact number, not a prefix: typing `1` means Al-Fatihah, not the
    // twenty-six surahs whose number happens to start with a one.
    if (needle == s.surahNumber.toString()) return true;
    if (needle.length < 2) return false;
    if (foldValueForSearch(s.nameUrdu).contains(needle)) return true;
    return s.id.contains(needle) || s.id.replaceAll('-', ' ').contains(needle);
  }).toList();
}
