import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/widgets/tafseer_html.dart';

void main() {
  const base = TextStyle(fontSize: 14, color: Color(0xFF111111));
  const bold = TextStyle(
    fontSize: 14,
    color: Color(0xFFB07A12),
    fontWeight: FontWeight.w600,
  );

  List<TextSpan> spans(String html) =>
      tafseerInlineSpans(html, base: base, bold: bold);

  test('plain definition becomes a single base span', () {
    final s = spans('چھپا ہوا خزانہ۔');
    expect(s, hasLength(1));
    expect(s.single.text, 'چھپا ہوا خزانہ۔');
    expect(s.single.style, base);
  });

  test('<b> segments are split out and styled bold', () {
    final s = spans('عین کی جمع؛ <b>اعیانِ ثابتہ</b>: ہر شے کی حقیقت۔');
    expect(s.map((e) => e.text).toList(), [
      'عین کی جمع؛ ',
      'اعیانِ ثابتہ',
      ': ہر شے کی حقیقت۔',
    ]);
    expect(s[0].style, base);
    expect(s[1].style, bold);
    expect(s[2].style, base);
  });

  test('handles multiple bold runs and leading/trailing markup', () {
    final s = spans('<b>کسب</b>: کوشش۔ <b>عطا</b>: بخشش۔');
    expect(s.map((e) => e.text).toList(), [
      'کسب',
      ': کوشش۔ ',
      'عطا',
      ': بخشش۔',
    ]);
    expect(s.where((e) => e.style == bold), hasLength(2));
  });

  test('unexpected tags degrade to plain text rather than showing markup', () {
    final s = spans('پہلے <i>ترچھا</i> پھر <b>موٹا</b>');
    final joined = s.map((e) => e.text).join();
    expect(joined, 'پہلے ترچھا پھر موٹا');
    expect(joined, isNot(contains('<')));
  });

  test('empty input yields no spans', () {
    expect(spans(''), isEmpty);
  });
}
