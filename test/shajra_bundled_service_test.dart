import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/services/shajra_bundled_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = ShajraBundledService();

  test('English list has 40 entries capped at #40', () async {
    final list = await service.loadEnglishList();
    expect(list.length, 40);
    expect(list.first.number, 1);
    expect(list.last.number, 40);
    expect(list.any((e) => e.number > 40), isFalse);
    expect(list.any((e) => e.number == 41), isFalse);
  });

  test('Urdu list has 40 entries capped at #40', () async {
    final list = await service.loadUrduList();
    expect(list.length, 40);
    expect(list.last.number, 40);
  });

  test('English detail HTML loads offline for entry 1 and 40', () async {
    final first = await service.loadEnglishDetailHtml(1);
    final last = await service.loadEnglishDetailHtml(40);
    expect(first, isNotNull);
    expect(first!.contains('<'), isTrue);
    expect(last, isNotNull);
    expect(last!.contains('Nisar Ahmad'), isTrue);
    expect(last.contains('11 September 1948'), isTrue);
  });

  test('Urdu biography loads offline for entry 40', () async {
    final html = await service.loadUrduDetailHtml(40);
    expect(html, isNotNull);
    expect(html!.contains('نثار احمد'), isTrue);
    expect(html.contains('ستمبر'), isTrue);
    expect(html.contains('۲۷ دسمبر ۱۹۶۷'), isTrue);
  });

  test('Entry 26 is Muhammad Zubair per Shajra document', () async {
    final urdu = await service.loadUrduList();
    expect(urdu[25].fullTitle, contains('محمد زبیر'));
  });

  test('Entry 39 and 40 list Muhammad Arif and Nisar Ahmad', () async {
    final urdu = await service.loadUrduList();
    expect(urdu[38].fullTitle, contains('محمد عارف'));
    expect(urdu[39].fullTitle, contains('سائیں صوفی نثار احمد'));
    expect(urdu[38].listDisplayName, startsWith('حضرت '));
    expect(urdu[38].listDisplayName, contains('خواجہ پیر سائیں محمد عارف'));
    expect(urdu[39].listDisplayName, startsWith('حضرت '));
    expect(urdu[39].listDisplayName, contains('خواجہ سائیں صوفی نثار احمد'));
  });

  test('Entry 1 does not use Khawaja honorific', () async {
    final english = await service.loadEnglishList();
    final urdu = await service.loadUrduList();
    final prophetEn = english.firstWhere((e) => e.number == 1);
    final prophetUr = urdu.firstWhere((e) => e.number == 1);
    expect(prophetEn.listDisplayName, 'Hazrat Muhammad Rasool Allah SAW');
    expect(prophetEn.listDisplayName, isNot(contains('Khawaja')));
    expect(prophetUr.listDisplayName, 'حضرت محمد رسول اللہ صلی اللہ علیہ وآلہ وسلم');
    expect(prophetUr.listDisplayName, isNot(contains('خواجہ')));
  });

  test('Urdu list uses short names for list display', () async {
    final urdu = await service.loadUrduList();
    final zubair = urdu.firstWhere((e) => e.number == 26);
    expect(zubair.listDisplayName, startsWith('حضرت خواجہ'));
    expect(zubair.listDisplayName, endsWith('رضی اللہ تعالیٰ عنہ'));
    expect(zubair.listDisplayName, contains('زبیر'));
  });

  test('English list short names use Hazrat Khawaja honorifics for 1-38', () async {
    final english = await service.loadEnglishList();
    final entry = english.firstWhere((e) => e.number == 2);
    expect(
      entry.listDisplayName,
      'Hazrat Khawaja Abu Bakr Siddiq Raziallah Taala Anhu',
    );
    final arif = english.firstWhere((e) => e.number == 39);
    expect(arif.listDisplayName, startsWith('Hazrat '));
    expect(arif.listDisplayName, contains('Khawaja Pir Sain Muhammad Arif'));
    expect(arif.listDisplayName, isNot(contains('Raziallah Taala Anhu')));
    final nisar = english.firstWhere((e) => e.number == 40);
    expect(nisar.listDisplayName, startsWith('Hazrat '));
    expect(nisar.listDisplayName, contains('Khawaja Saeen Sufi Nisar Ahmad'));
    expect(nisar.fullTitle, contains('Khawaja'));
    expect(arif.fullTitle, contains('Khawaja'));
  });
}
