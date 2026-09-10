/// Converts Western digits in [value] to Urdu-Indic digits (۰-۹), matching the
/// numerals used throughout the bundled tafseer content.
String toUrduDigits(Object value) {
  const digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return value.toString().split('').map((ch) {
    final code = ch.codeUnitAt(0) - 0x30;
    return code >= 0 && code <= 9 ? digits[code] : ch;
  }).join();
}
